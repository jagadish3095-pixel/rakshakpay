"""Java from the basics: an explainer video built on one real program (the Clinic Appointment Scheduler).

    python make_java.py <src_dir> <work_dir> <out.mp4 | preview>

<src_dir> is the project's `src` folder (it holds clinic/model, clinic/exception, ...). The code on screen is
read from those files, so the line numbers always match. Uses the engine of make_video.py: one narrated
sentence at a time, and the highlighted lines change with the sentence.
"""

import pathlib
import re
import sys

from PIL import Image, ImageDraw, ImageFont

import make_video as mv
from make_video import AMBER, CARD, GREEN, NAVY, PURPLE, RED, SAFFRON, SOFT, WHITE, El, center_x, place_shadowed

BLUE = (90, 160, 255)
TEAL = (78, 201, 176)

# VS Code dark colours for the code
C_BG, C_GUTTER, C_BAR = (30, 30, 34), (110, 118, 129), (45, 45, 52)
C_TEXT, C_KW, C_CTRL, C_TYPE = (212, 212, 212), (86, 156, 214), (197, 134, 192), (78, 201, 176)
C_STR, C_COM, C_NUM, C_FN, C_ANN = (206, 145, 120), (106, 153, 85), (181, 206, 168), (220, 220, 170), (220, 220, 170)

KEYWORDS = set("""package import public private protected static final abstract class interface enum extends implements
new this super void int boolean long char double true false null synchronized""".split())
CONTROL = set("if else for while do switch case default break return try catch finally throw throws".split())
TOKEN = re.compile(r'(//.*$|/\*\*.*?\*/|/\*.*$|^\s*\*.*$|"(?:[^"\\]|\\.)*"|@\w+|\b\d+\b|\b\w+\b|\s+|.)')

PANEL_X, PANEL_Y, PANEL_W, PANEL_MAXH = 100, 205, 1260, 725
NOTE_W = 430


def mono(size, bold=False):
    return ImageFont.truetype(f"{mv.FONTS}\\{'consolab' if bold else 'consola'}.ttf", size)


def tokens(line, lang):
    if lang != "java":
        return [(line, C_TEXT)]
    out = []
    for m in TOKEN.finditer(line):
        t = m.group(0)
        rest = line[m.end():].lstrip()
        if t.startswith(("//", "/*")) or (t.lstrip().startswith("*") and not out):
            c = C_COM
        elif t.startswith('"'):
            c = C_STR
        elif t.startswith("@"):
            c = C_ANN
        elif t.isdigit():
            c = C_NUM
        elif t in CONTROL:
            c = C_CTRL
        elif t in KEYWORDS:
            c = C_KW
        elif t[:1].isupper() and t[:1].isalpha():
            c = C_TYPE
        elif t[:1].isalpha() and rest.startswith("("):
            c = C_FN
        else:
            c = C_TEXT
        out.append((t, c))
    return out


def parse_hl(spec):
    """'14' or '25-32' or '23,25,40-44' -> set of line numbers; None -> no highlight."""
    if spec is None:
        return None
    lines = set()
    for part in str(spec).split(","):
        a, _, b = part.partition("-")
        lines.update(range(int(a), int(b or a) + 1))
    return lines


def code_panel(title, rows, hl=None, lang="java", width=PANEL_W, maxh=PANEL_MAXH, numbers=True):
    """rows: [(line_no or None, text)]; None draws a '⋮' gap. hl: set of line numbers to focus on."""
    n = len(rows)
    indent = min((len(t) - len(t.lstrip()) for no, t in rows if no is not None and t.strip()), default=0)
    rows = [(no, t[indent:].rstrip()) for no, t in rows]
    lh = min(42, int((maxh - 80) / n))
    cw = mono(100).getlength("x") / 100 * 0.72  # char width per pixel of line height

    extra = (4 if numbers else 0) + 3

    def is_comment(t):
        return lang == "java" and t.lstrip().startswith(("//", "/*", "*"))

    def lh_for(rs):  # comment-only lines don't count: they are cut short instead
        widest = max((len(t) for _, t in rs if not is_comment(t)), default=1) + extra
        return int((width - 40) / (cw * widest))

    if lh_for(rows) < lh:
        stripped = [(no, re.sub(r"\s+//.*$", "", t) if lang == "java" and not is_comment(t) else t)
                    for no, t in rows]
        if lh_for(stripped) > lh_for(rows):
            rows = stripped
        lh = max(min(lh, lh_for(rows)), min(lh, 26))
    room = int((width - 40) / (cw * lh)) - extra
    rows = [(no, t if len(t) <= room else t[:room - 1] + "…") for no, t in rows]
    f = mono(int(lh * 0.72))
    gw = int(f.getlength("0000")) + 30 if numbers else 30
    head = 54
    h = head + lh * n + 26
    im = mv.rounded((width, h), 18, C_BG + (255,))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, width - 1, head), 18, fill=C_BAR)
    d.rectangle((0, head - 18, width - 1, head), fill=C_BAR)
    for i, col in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse((22 + i * 30, 19, 38 + i * 30, 35), fill=col)
    d.text((126, 12), title, font=mono(26), fill=(200, 200, 210))
    for i, (no, text) in enumerate(rows):
        y = head + 12 + i * lh
        focus = hl is None or no in hl
        if hl is not None and no in hl:
            d.rectangle((0, y - 2, width - 1, y + lh - 2), fill=(255, 143, 31, 46))
            d.rectangle((0, y - 2, 6, y + lh - 2), fill=SAFFRON)
        if no is None:
            d.text((gw - 18 - f.getlength(".."), y), "..", font=f, fill=C_GUTTER)
            continue
        if numbers:
            d.text((gw - 18 - f.getlength(str(no)), y), str(no), font=f, fill=C_GUTTER)
        x = gw
        for t, c in tokens(text, lang):
            if not focus:
                c = tuple(int(v * 0.42 + C_BG[k] * 0.58) for k, v in enumerate(c))
            d.text((x, y), t, font=f, fill=c)
            x += f.getlength(t)
    return im


def term_panel(lines, width=PANEL_W, maxh=PANEL_MAXH):
    """A console window. Text in {braces} is what the user typed (amber); lines starting '+' green, '!' red."""
    n = len(lines)
    lh = min(40, int((maxh - 80) / n))
    f = mono(int(lh * 0.72))
    head = 54
    im = mv.rounded((width, head + lh * n + 26), 18, (12, 12, 16, 255))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, width - 1, head), 18, fill=(40, 40, 48))
    d.rectangle((0, head - 18, width - 1, head), fill=(40, 40, 48))
    d.text((26, 12), "Command Prompt", font=mono(26), fill=(200, 200, 210))
    for i, line in enumerate(lines):
        y, x = head + 12 + i * lh, 26
        base = (204, 204, 204)
        if line.startswith("+"):
            line, base = line[1:], GREEN
        elif line.startswith("!"):
            line, base = line[1:], RED
        elif line.startswith(">"):
            d.text((x, y), "C:\\ClinicSimple>", font=f, fill=(140, 140, 150))
            x += f.getlength("C:\\ClinicSimple>")
            line, base = line[1:], WHITE
        for k, part in enumerate(re.split(r"[{}]", line)):
            d.text((x, y), part, font=f, fill=AMBER if k % 2 else base)
            x += f.getlength(part)
    return im


def note_card(title, body, color=SAFFRON, w=NOTE_W):
    t = mv.text_img(title, 34, "bold", WHITE, max_w=w - 56)
    b = mv.text_img(body, 27, "regular", SOFT, max_w=w - 56) if body else None
    h = 34 + t.height + (b.height + 8 if b else 0) + 22
    im = mv.rounded((w, h), 20, CARD + (255,))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, 9, h - 1), 4, fill=color)
    im.alpha_composite(t, (30, 22))
    if b:
        im.alpha_composite(b, (30, 22 + t.height + 6))
    return im


def L_panel(heading, versions, notes=(), wide=False):
    """versions: [(sentence index, panel image)]. Later versions fade in over earlier ones in the same spot."""
    els = mv.L_heading(heading)
    x = center_x(versions[0][1]) if wide else PANEL_X
    els.append(place_shadowed(versions[0][1], x, PANEL_Y, at=versions[0][0]))
    for at, img in versions[1:]:
        els.append(El(img, x, PANEL_Y, at=at, slide=0))
    y = PANEL_Y
    compact = len(notes) > 4
    for at, title, body, color in notes:
        c = note_card(f"{title}: {body}" if compact and body else title, None if compact else body, color)
        els.append(El(c, PANEL_X + PANEL_W + 30, y, at=at))
        y += c.height + 22
    return els


# ---------------------------------------------------------------- beats

def beats(src: pathlib.Path):
    cache = {}

    def lines_of(path):
        if path not in cache:
            cache[path] = (src / "clinic" / path).read_text(encoding="utf-8").splitlines()
        return cache[path]

    def rows(path, ranges):
        out, prev = [], None
        for a, b in ranges:
            if prev is not None and a > prev + 1:
                out.append((None, ""))
            out += [(i, lines_of(path)[i - 1]) for i in range(a, b + 1)]
            prev = b
        return out

    def code(label, heading, path, ranges, sentences, hls, notes=(), wide=False):
        """One beat on one file. hls[i] = lines to highlight while sentence i is spoken."""
        assert len(hls) == len(sentences), (heading, len(hls), len(sentences))
        r = rows(path, ranges)
        versions, last = [], object()
        for i, spec in enumerate(hls):
            if spec != last:
                versions.append((i, code_panel(f"clinic/{path}", r, parse_hl(spec),
                                               width=1720 if wide else PANEL_W)))
                last = spec
        return ("code", label, sentences, L_panel(heading, versions, notes, wide))

    def tree(label, heading, sentences, hls, notes=()):
        listing = [
            "ClinicSimple/",
            "├── run.bat",
            "└── src/",
            "    └── clinic/",
            "        ├── model/        Person  Patient  Doctor",
            "        │                 TimeSlot  Appointment",
            "        ├── exception/    ClinicException",
            "        │                 SlotUnavailableException",
            "        ├── service/      AppointmentService  ClinicService",
            "        └── app/          Main",
        ]
        r = [(i + 1, t) for i, t in enumerate(listing)]
        versions, last = [], object()
        for i, spec in enumerate(hls):
            if spec != last:
                versions.append((i, code_panel("Project folders", r, parse_hl(spec), lang="text", numbers=False)))
                last = spec
        return ("code", label, sentences, L_panel(heading, versions, notes))

    def term(label, heading, sentences, lines, notes=()):
        return ("code", label, sentences, L_panel(heading, [(0, term_panel(lines))], notes))

    menu = ["======= CLINIC APPOINTMENT SCHEDULER =======",
            "1. View doctors and slots   5. Cancel appointment",
            "2. Search doctor            6. My upcoming appointments",
            "3. Register patient         7. View log file",
            "4. Book appointment         8. Booking race demo (threads)",
            "0. Exit"]

    return [
        ("title", "", ["Java, from the basics.",
                       "We will learn Java by reading one real program: a clinic appointment scheduler."],
         L_title("Java, from the basics", "Learn Java by reading one real program, line by line.",
                 "Clinic Appointment Scheduler  •  10 files  •  4 packages")),

        # ---------------- basics
        ("basics", "PART 1  •  THE BASICS",
         ["Java is one of the most popular programming languages in the world.",
          "It is object oriented: we model the program as objects, like doctors, patients and appointments.",
          "It is strongly typed: every variable has a fixed type, so many mistakes are caught before the program "
          "even runs.",
          "And the same program runs on Windows, Linux or Mac, anywhere Java is installed."],
         mv.L_rows("What is Java?", [
             ("Popular", "Used for banking systems, Android apps, websites and big servers", "☕", SAFFRON),
             ("Object oriented", "The program is built from objects: Doctor, Patient, Appointment", "◆", BLUE),
             ("Strongly typed", "Every variable has a type, checked before the program runs", "✔", GREEN),
             ("Runs anywhere", "Write once, run on any computer with Java", "⚙", PURPLE)], y0=290, gap=150)),
        ("basics", "PART 1  •  THE BASICS",
         ["You write your code in .java files.",
          "The compiler, javac, translates them into bytecode, saved in .class files.",
          "Then the Java Virtual Machine, the JVM, runs that bytecode."],
         mv.L_flow("From code to a running program", [
             ("Main.java", "the code you write", "✎", SAFFRON),
             ("javac", "compiles it to Main.class", "⚙", BLUE),
             ("JVM", "runs the bytecode", "▶", GREEN)], [0, 1, 2])),
        term("PART 1  •  THE BASICS", "Compile and run",
             ["For our project, two commands are enough.",
              "javac -d out compiles every file, and puts the .class files in a folder called out.",
              "Then java -cp out clinic.app.Main starts the program, from the class called Main."],
             [">javac -d out src\\clinic\\model\\*.java src\\clinic\\exception\\*.java",
              "            src\\clinic\\service\\*.java src\\clinic\\app\\*.java",
              "",
              ">java -cp out clinic.app.Main",
              ""] + menu + ["Choice: {_}"],
             notes=[(1, "javac", "the compiler: .java to .class", BLUE),
                    (2, "java", "runs the program, starting at main", GREEN)]),
        ("basics", "PART 1  •  THE BASICS",
         ["The program we will study is a clinic appointment scheduler.",
          "It runs in the console, shows a menu, and lets patients register, book and cancel appointments.",
          "And its most important rule: one slot can never be booked by two patients, even if they try at the "
          "same moment."],
         L_grid3("What the program does", [
             ("Doctors & slots", "See every doctor's schedule", "\U0001F468", BLUE),
             ("Register", "Get a patient ID like P1001", "✎", GREEN),
             ("Book", "Pick a free slot", "✔", GREEN),
             ("Cancel", "The slot is free again", "✖", AMBER),
             ("Upcoming", "Your appointments, sorted", "⏱", PURPLE),
             ("Log file", "Every action is recorded", "▤", SOFT)], ats=[1, 1, 1, 1, 1, 1],
             footer=("One slot, one patient. Always.", 2))),

        # ---------------- packages
        tree("PART 2  •  PACKAGES", "Packages: folders for classes",
             ["The ten files are organised into packages.",
              "A package is simply a folder that groups related classes, and gives each class a full name, like "
              "clinic.model.Doctor.",
              "model holds the data: Person, Patient, Doctor, TimeSlot and Appointment.",
              "exception holds our own error types.",
              "service holds the business rules.",
              "And app holds Main, the menu that starts everything."],
             [None, "4", "5-6", "7-8", "9", "10"],
             notes=[(2, "model", "the data", BLUE), (3, "exception", "our errors", RED),
                    (4, "service", "the rules", GREEN), (5, "app", "the menu, starts here", SAFFRON)]),
        code("PART 2  •  PACKAGES", "package and import", "app/Main.java", [(1, 16)],
             ["Every file starts with a package line, and it must match the folder: Main.java lives in clinic, "
              "then app.",
              "Then come the imports. To use a class from another package, we import it by its full name.",
              "Classes from Java's own library are imported the same way: List and Scanner come from java.util.",
              "Classes like String and System are in java.lang, and need no import at all."],
             ["1", "3-10", "12-13", None],
             notes=[(0, "package", "where this class lives", SAFFRON),
                    (1, "import", "use a class from another package", BLUE),
                    (3, "java.lang", "String, System, Integer: always available", GREEN)]),

        # ---------------- classes and objects
        code("PART 3  •  CLASSES AND OBJECTS", "A class is a blueprint", "model/Patient.java", [(1, 21)],
             ["Let's start with the most basic building block: a class.",
              "A class is a blueprint. Patient describes what every patient has.",
              "These are fields: the data each patient carries. Here, an age and a phone number.",
              "private means only code inside this class can touch them.",
              "final means the value is set once, and never changes.",
              "This is the constructor. It runs when a new patient is created, and fills in the fields.",
              "this.age means the field of this object, while plain age is the value that was passed in.",
              "Getters let other classes read the values, without being able to change them.",
              "Hiding data behind methods like this is called encapsulation."],
             [None, "4", "5-6", "5-6", "5-6", "8-12", "10-11", "14-15", "14-15"],
             notes=[(1, "class", "a blueprint", SAFFRON),
                    (2, "field", "data inside each object", BLUE),
                    (5, "constructor", "builds a new object", GREEN),
                    (7, "getter", "read-only access", PURPLE)]),
        code("PART 3  •  CLASSES AND OBJECTS", "An object is made with new", "service/ClinicService.java",
             [(119, 125)],
             ["An object is one real thing built from the blueprint.",
              "We create it with the keyword new, which calls the constructor.",
              "Here the service makes a patient with an ID like P1001, plus the name, age and phone.",
              "Then the counter goes up by one, so the next patient gets P1002, and the patient is added to the list."],
             [None, "120", "120", "121-122"],
             notes=[(0, "Class", "Patient: the blueprint", SAFFRON),
                    (0, "Object", "Ravi, P1001, 34 years: one real patient", GREEN),
                    (1, "new", "creates an object and runs the constructor", BLUE)]),
        code("PART 3  •  CLASSES AND OBJECTS", "Every value has a type", "model/TimeSlot.java", [(7, 21)],
             ["Every field and variable in Java has a type.",
              "String holds text, like the slot ID D1-S1.",
              "A class is a type too: the doctor field holds a Doctor object.",
              "LocalDateTime, from Java's library, holds a date and a time.",
              "boolean is just true or false: is this slot booked?",
              "And int, which we saw in Patient, holds whole numbers like an age."],
             [None, "12", "13", "14", "15", None],
             notes=[(1, "String", "text", SAFFRON), (2, "Doctor", "one of our own classes", BLUE),
                    (3, "LocalDateTime", "date and time", PURPLE), (4, "boolean", "true or false", GREEN),
                    (5, "int", "whole numbers", AMBER)]),

        # ---------------- inheritance
        code("PART 4  •  INHERITANCE", "A parent class: Person", "model/Person.java", [(3, 23)],
             ["Patients and doctors both have an ID and a name.",
              "Instead of writing that twice, both inherit it from one parent class: Person.",
              "Person is abstract. You can never create a plain Person, only a Patient or a Doctor.",
              "Its constructor is protected, so only its child classes can call it.",
              "getDetails is an abstract method: it has no body. Every child class must write its own version.",
              "And toString is the method Java calls whenever an object is printed. Here it simply returns "
              "getDetails."],
             ["5-6", "5-6", "4", "8-11", "17", "19-22"],
             notes=[(2, "abstract class", "a parent you can't create directly", SAFFRON),
                    (3, "protected", "visible to child classes", BLUE),
                    (4, "abstract method", "no body; children must write it", PURPLE)]),
        code("PART 4  •  INHERITANCE", "A child class: Patient extends Person", "model/Patient.java", [(1, 21)],
             ["Patient extends Person.",
              "That one word, extends, gives Patient the ID, the name, and both getters, for free.",
              "super, with the ID and name, calls Person's constructor first, to build the Person part.",
              "The Override annotation says: I am replacing my parent's method.",
              "So a Patient describes itself with its ID, name and age."],
             ["4", "4", "9", "17", "18-20"],
             notes=[(0, "extends", "inherit from a parent class", SAFFRON),
                    (2, "super(...)", "call the parent's constructor", BLUE),
                    (3, "@Override", "replace the parent's method", GREEN)]),
        code("PART 4  •  INHERITANCE", "Polymorphism: same call, different behaviour", "app/Main.java", [(68, 75)],
             ["Now see the power of this.",
              "Main prints a doctor just by adding it to a string.",
              "Java calls toString, which calls getDetails, and the Doctor's own version runs.",
              "Print a patient the same way, and the Patient's version runs instead.",
              "One call, different behaviour for different objects. This is called polymorphism."],
             [None, "70", "70", "70", "70"],
             notes=[(2, "Doctor", "D1 | Dr. Anjali Rao | General Physician", BLUE),
                    (3, "Patient", "P1001 | Ravi Kumar | Age 34", GREEN),
                    (4, "polymorphism", "many forms of one method", SAFFRON)]),

        # ---------------- interface
        code("PART 5  •  INTERFACES", "An interface is a contract", "service/AppointmentService.java",
             [(10, 30)],
             ["An interface is a list of methods, with no code inside. Think of it as a contract.",
              "AppointmentService lists what the clinic can do: get doctors, register patients, book and cancel "
              "appointments, and read the log.",
              "throws ClinicException warns the caller: this method can fail, so be ready to handle it."],
             ["11", "13-29", "17,19,23,25,27"],
             notes=[(0, "interface", "what can be done, not how", SAFFRON),
                    (2, "throws", "this method may fail", RED)]),
        code("PART 5  •  INTERFACES", "Implementing the contract", "service/ClinicService.java", [(19, 28)],
             ["ClinicService implements the interface, so it must write every one of those methods.",
              "In Main, the service is stored in a variable of the interface type, AppointmentService.",
              "So the menu only knows what the service can do, not how it does it.",
              "We could swap in a different service tomorrow, and the menu would not change at all."],
             ["20", "20", "20", "20"],
             notes=[(0, "implements", "keeps the interface's promise", SAFFRON),
                    (1, "Main.java, line 18", "AppointmentService service = new ClinicService();", BLUE)]),

        # ---------------- arrays, loops, methods
        code("PART 6  •  ARRAYS AND METHODS", "An array: the doctor's schedule", "model/Doctor.java", [(9, 20)],
             ["A doctor keeps their schedule in an array.",
              "An array holds many values of one type, and its size is fixed. This one holds ten time slots.",
              "MAX_SLOTS is static final: a constant, shared by the whole class, that never changes.",
              "slotCount remembers how many places in the array are actually filled.",
              "And the constructor calls super, just like Patient, then stores the specialization."],
             [None, "14", "11", "15", "17-20"],
             notes=[(1, "TimeSlot[ ]", "an array of slots, size 10", SAFFRON),
                    (2, "static final", "a constant", BLUE),
                    (3, "slots[0] … slots[9]", "index starts at zero", GREEN)]),
        code("PART 6  •  ARRAYS AND METHODS", "Methods, overloading and varargs", "model/Doctor.java", [(24, 44)],
             ["A method is a named block of code. addSlot puts a new slot into the next free place in the array.",
              "It builds an ID like D1-S1, stores the slot, and adds one to the count.",
              "If the array is already full, it throws an exception instead.",
              "Here is a second addSlot, with different parameters: a date and an hour.",
              "Same name, different parameters. This is called method overloading.",
              "addSlots, with three dots, accepts any number of hours. This is called varargs.",
              "And the for each loop runs once for every hour that was passed in."],
             ["25-32", "29-31", "26-28", "35-37", "25,35", "40", "41-43"],
             notes=[(4, "overloading", "same name, different parameters", SAFFRON),
                    (5, "varargs  int...", "any number of values", BLUE),
                    (6, "for each", "for (int hour : hours)", GREEN)]),
        code("PART 6  •  ARRAYS AND METHODS", "Loops and conditions", "model/Doctor.java", [(53, 71)],
             ["getFreeSlots uses the classic for loop.",
              "It has three parts: start i at zero, keep going while i is less than slotCount, and add one each "
              "time.",
              "if checks a condition. The exclamation mark means not, and the double ampersand means and.",
              "So a slot is free if it is not booked, and not in the past.",
              "findSlot loops the same way, and compares IDs with equalsIgnoreCase, so small d1-s1 still matches.",
              "If nothing matches, it returns null, which means: no object."],
             ["55", "55", "56", "56-58", "65-69", "70"],
             notes=[(1, "for (start; check; step)", "i = 0;  i < slotCount;  i++", SAFFRON),
                    (2, "!   &&   ||", "not,  and,  or", BLUE),
                    (5, "null", "no object", RED)]),
        code("PART 6  •  ARRAYS AND METHODS", "Lists that grow", "service/ClinicService.java", [(23, 27)],
             ["An array has a fixed size. But how many patients will register? We don't know.",
              "So patients and appointments are kept in an ArrayList, which grows by itself.",
              "The angle brackets say what the list holds. A List of Patient can only hold patients. These are "
              "called generics.",
              "We add items with add, and loop through them with for each, just like an array.",
              "The doctors, three of them, are fixed, so they stay in a plain array."],
             [None, "24-25", "24", "24-25", "23"],
             notes=[(1, "ArrayList", "a list that grows", SAFFRON),
                    (2, "List<Patient>", "generics: only Patients inside", BLUE),
                    (3, "list.add(p)", "add at the end", GREEN)]),

        # ---------------- strings and validation
        code("PART 7  •  STRINGS AND CHECKS", "Checking the input", "service/ClinicService.java", [(92, 108)],
             ["Now the rules. registerPatient checks every input before it creates a patient.",
              "trim removes spaces from both ends.",
              "matches checks the text against a pattern, called a regular expression: two to forty letters or "
              "spaces.",
              "The age arrives as text, so Integer.parseInt converts it to a number.",
              "If the text is not a number, parseInt throws a NumberFormatException.",
              "We catch it, and throw our own ClinicException instead, with a friendly message.",
              "Then a simple range check: the age must be between 1 and 120."],
             ["93-94", "95", "96-98", "100-102", "102-103", "103-105", "106-108"],
             notes=[(1, "trim()", "\"  Ravi \"  →  \"Ravi\"", SAFFRON),
                    (2, "matches(regex)", "[A-Za-z ]{2,40}", BLUE),
                    (3, "Integer.parseInt", "\"34\"  →  34", GREEN)]),
        code("PART 7  •  STRINGS AND CHECKS", "More checks, then save", "service/ClinicService.java",
             [(110, 125)],
             ["The phone must be ten digits, starting with 6, 7, 8 or 9.",
              "A loop makes sure the same phone is not registered twice.",
              "Comparing strings uses equals, not double equals. equals compares the text itself.",
              "Only when every check passes is the patient created, added to the list, and written to the log."],
             ["110-113", "114-118", "115", "120-124"],
             notes=[(0, "[6-9][0-9]{9}", "one of 6 to 9, then nine digits", SAFFRON),
                    (2, "a.equals(b)", "same text?  Use this for Strings", GREEN)]),

        # ---------------- exceptions
        code("PART 8  •  EXCEPTIONS", "Our own exception", "exception/ClinicException.java", [(1, 15)],
             ["When something goes wrong, Java throws an exception, an object that describes the error.",
              "ClinicException extends Exception, so it is our own error type.",
              "Because it extends Exception, it is a checked exception. The compiler forces every caller to handle "
              "it, or to declare it with throws.",
              "super passes the message up to Exception, and getMessage returns it later.",
              "The second constructor also keeps the original error as the cause."],
             [None, "4", "4", "7-9", "12-14"],
             notes=[(1, "extends Exception", "a checked exception", RED),
                    (3, "e.getMessage()", "the error text", BLUE)]),
        code("PART 8  •  EXCEPTIONS", "A more specific exception", "exception/SlotUnavailableException.java",
             [(1, 10)],
             ["SlotUnavailableException extends ClinicException.",
              "So it is a more specific kind of clinic error: for a slot that is taken, in the past, or clashing "
              "with another booking.",
              "Exceptions can form a family tree, just like classes."],
             ["4", "3-4", None],
             notes=[(2, "Exception", "Java's parent of all checked errors", SOFT),
                    (2, "ClinicException", "extends Exception", AMBER),
                    (2, "SlotUnavailable Exception", "extends ClinicException", RED)]),
        code("PART 8  •  EXCEPTIONS", "try, catch and finally", "app/Main.java", [(20, 27), (38, 47)],
             ["In Main, the risky work happens inside try.",
              "If an exception is thrown, Java jumps straight to the matching catch block.",
              "The more specific SlotUnavailableException is caught first, then the general ClinicException.",
              "If the order were reversed, the compiler would complain, because the first catch would swallow both.",
              "finally always runs, error or not. Here it closes the Scanner.",
              "Because the error is caught, the program prints a message and shows the menu again, instead of "
              "crashing."],
             ["26-27,38", "39-43", "39-43", "39-43", "45-47", "23,44"],
             notes=[(0, "try", "the risky code", SAFFRON), (1, "catch", "handle a specific error", RED),
                    (4, "finally", "always runs", GREEN)]),
        code("PART 8  •  EXCEPTIONS", "Files and try-with-resources", "service/ClinicService.java", [(212, 233)],
             ["Every action is written to a log file.",
              "This is try with resources. The FileWriter opened inside the brackets is closed automatically.",
              "true means append: add to the end of the file, instead of wiping it.",
              "Reading uses a BufferedReader, one line at a time, until readLine returns null at the end of the file.",
              "If the file doesn't exist yet, the IOException is caught, and a friendly line is shown instead."],
             ["213", "214", "214", "224-228", "229-231"],
             notes=[(1, "try ( ... )", "closes the file for you", SAFFRON),
                    (3, "readLine()", "null at the end", BLUE)]),

        # ---------------- main and the menu
        code("PART 9  •  THE MENU", "main: where the program starts", "app/Main.java", [(16, 38)],
             ["Main is where the program starts.",
              "A Scanner reads what the user types on the keyboard.",
              "static means these belong to the class itself, not to any one object.",
              "public static void main, with String args, is the entry point. Java looks for exactly this method.",
              "do while repeats: show the menu, read a choice, act on it, and repeat until the user enters zero.",
              "switch jumps to the case that matches the choice. Each case calls one method.",
              "break stops it from running into the next case. And default handles anything else."],
             ["16", "17", "17-18", "20", "23-25", "27-35", "28-37"],
             notes=[(3, "main", "the starting point", SAFFRON), (4, "do { } while ( )", "loop at least once", BLUE),
                    (5, "switch / case", "choose by value", GREEN)]),
        code("PART 9  •  THE MENU", "One small method per action", "app/Main.java", [(96, 111)],
             ["Each menu option is a small method.",
              "bookAppointment asks for the patient ID and the doctor, through the service.",
              "If the doctor has no free slots, return leaves the method early.",
              "Otherwise it lists the free slots, asks for a slot ID, and books it.",
              "Notice: Main never checks the rules itself. That is the service's job."],
             ["96", "97-99", "100-103", "104-110", "109"]),

        # ---------------- appointment, enum, StringBuffer
        code("PART 10  •  ENUMS", "Appointment and its status", "model/Appointment.java", [(3, 18), (25, 30)],
             ["An appointment links one patient to one time slot.",
              "Inside it is a nested enum. An enum is a type with a fixed set of values: here, BOOKED or CANCELLED.",
              "Every new appointment starts as BOOKED.",
              "isActive compares with double equals, which is the right way for enum values.",
              "And cancel changes the status, and frees the slot again."],
             ["4,10-11", "7", "12", "25", "27-30"],
             notes=[(1, "enum", "a fixed set of values", SAFFRON)]),
        code("PART 10  •  ENUMS", "Building text with StringBuffer", "model/Appointment.java", [(32, 42)],
             ["getDetails builds a text of five lines.",
              "A StringBuffer collects the pieces.",
              "append adds a piece and returns the same buffer, so the calls can be chained, one after another.",
              "toString turns it back into a normal String."],
             ["33", "34", "35-40", "41"],
             notes=[(2, "sb.append(a).append(b)", "chained calls", SAFFRON)]),
        code("PART 10  •  ENUMS", "The booking rules", "service/ClinicService.java", [(145, 148), (150, 163), (166, 170)],
             ["Now the heart of the program: booking.",
              "First the service finds the patient and the slot. If either is missing, an exception is thrown.",
              "Rule one: you cannot book a slot in the past.",
              "Rule two: you cannot hold two appointments at the same time.",
              "Rule three: tryBook must succeed. If the slot is already booked, the booking is rejected.",
              "Only then is the appointment created, added to the list, and logged."],
             ["145-146", "147-148", "150-152", "153-159", "160-164", "166-170"]),

        # ---------------- sorting and lambdas
        code("PART 11  •  SORTING AND LAMBDAS", "Teaching Java to compare slots", "model/TimeSlot.java",
             [(8, 8), (43, 47)],
             ["How does Java know which slot comes first?",
              "TimeSlot implements Comparable, which is Java's way of saying: these objects can be put in order.",
              "compareTo compares the two times, so the earlier slot comes first."],
             [None, "8", "44-46"],
             notes=[(1, "Comparable", "objects with a natural order", SAFFRON)]),
        code("PART 11  •  SORTING AND LAMBDAS", "Sorting, and returning a copy", "model/Doctor.java", [(46, 51)],
             ["Arrays.sort uses that compareTo to sort the schedule.",
              "And getSlots returns a copy of the array, so nobody outside can change the doctor's real schedule."],
             ["49", "48,50"]),
        code("PART 11  •  SORTING AND LAMBDAS", "A lambda: a function written inline", "service/ClinicService.java",
             [(196, 208)],
             ["getUpcomingAppointments collects one patient's active, future appointments.",
              "Then it sorts them with a lambda: a short function, written right where it is needed.",
              "Given two appointments, a and b, compare their slots. Earliest first."],
             ["201-205", "206", "206"],
             notes=[(1, "(a, b) -> ...", "a lambda", SAFFRON)]),

        # ---------------- threads
        code("PART 12  •  THREADS", "Two patients, one slot, same moment", "model/TimeSlot.java", [(30, 41)],
             ["Now the most advanced idea: threads.",
              "A thread is a separate path of work. Several threads can run at the same time.",
              "If two patients try to book the same slot at the same moment, both might see it free, and both "
              "might book it.",
              "The keyword synchronized prevents this. Only one thread at a time can be inside tryBook on a slot.",
              "So the first thread sets booked to true, and the second one finds it already booked, and gets false."],
             [None, None, "34-38", "33", "34-38"],
             notes=[(1, "thread", "work that runs alongside other work", SAFFRON),
                    (3, "synchronized", "one thread at a time", GREEN)]),
        code("PART 12  •  THREADS", "The booking race demo", "app/Main.java", [(145, 166)],
             ["Option eight proves it.",
              "It creates one thread for every registered patient.",
              "Each thread gets a lambda: the work to run, which is to try to book the same slot.",
              "start launches all the threads together.",
              "join waits for each one to finish."],
             [None, "145-147", "148-155", "157-159", "160-166"],
             notes=[(3, "t.start()", "run now, in parallel", SAFFRON), (4, "t.join()", "wait until done", BLUE)]),

        # ---------------- run it
        term("PART 13  •  RUN IT", "Let's run it",
             ["Let's run the whole program.",
              "Option one lists every doctor and their slots, sorted by time, each one printed with toString."],
             ["Choice: {1}", "",
              "D1 | Dr. Anjali Rao | General Physician",
              "    D1-S1   Fri 30-Oct-2026 09:00 AM   [FREE]",
              "    D1-S2   Fri 30-Oct-2026 10:00 AM   [FREE]",
              "    D1-S3   Fri 30-Oct-2026 11:00 AM   [FREE]",
              "",
              "D2 | Dr. Rahul Mehta | Cardiology",
              "    D2-S1   Fri 30-Oct-2026 10:00 AM   [FREE]",
              "    D2-S2   Fri 30-Oct-2026 12:00 PM   [FREE]",
              "",
              "D3 | Dr. Sneha Iyer | Pediatrics",
              "    D3-S1   Fri 30-Oct-2026 02:00 PM   [FREE]"]),
        term("PART 13  •  RUN IT", "Register, book, and a rejection",
             ["Option three registers Ravi, who gets the ID P1001. Meena becomes P1002.",
              "Ravi books slot D1-S1, and gets appointment A5001.",
              "When Meena tries the same slot, the SlotUnavailableException is thrown, caught in Main, and shown "
              "as a friendly message."],
             ["Choice: {3}",
              "Name: {Ravi Kumar}   Age: {34}   Phone (10 digits): {9876543210}",
              "+  Registered! Your patient ID is P1001",
              "",
              "Choice: {4}",
              "Your patient ID: {P1001}   Doctor ID (D1, D2, D3): {D1}   Slot ID: {D1-S1}",
              "+  Booked!",
              "  Appointment : A5001",
              "  Patient     : Ravi Kumar",
              "  Doctor      : Dr. Anjali Rao (General Physician)",
              "  Status      : BOOKED",
              "",
              "Choice: {4}",
              "Your patient ID: {P1002}   Doctor ID (D1, D2, D3): {D1}   Slot ID: {D1-S1}",
              "!  Slot problem: Slot D1-S1 is already booked. Please choose another slot."]),
        term("PART 13  •  RUN IT", "The race: threads in action",
             ["And option eight: both patients try to grab slot D2-S1 at the same moment, on two threads.",
              "Exactly one succeeds. The other is rejected. Thanks to synchronized, a slot can never be booked "
              "twice."],
             ["Choice: {8}",
              "Slot ID that everyone will try to book: {D2-S1}",
              "+  P1002: SUCCESS, got A5002",
              "!  P1001: REJECTED, Slot D2-S1 is already booked. Please choose another slot.",
              "  A slot can be given to only one patient, however many try at once.",
              "",
              "Choice: {0}",
              "Goodbye!"]),

        # ---------------- recap and end
        ("recap", "RECAP",
         ["Let's recap what this one program taught us.",
          "Packages and imports organise the code. Classes and objects model the data, with encapsulation.",
          "Inheritance, abstract classes and polymorphism share and specialise behaviour. Interfaces define "
          "contracts.",
          "Arrays, lists, loops and conditions handle the data. Exceptions handle errors, and files keep a log.",
          "And enums, lambdas and synchronized threads finish the picture."],
         L_grid3("What you learned", [
             ("Packages", "folders + import", "▤", SAFFRON),
             ("Classes & objects", "blueprint + new", "◆", SAFFRON),
             ("Encapsulation", "private + getters", "\U0001F512", SAFFRON),
             ("Inheritance", "extends, abstract", "↑", BLUE),
             ("Polymorphism", "@Override", "✱", BLUE),
             ("Interfaces", "implements", "✔", BLUE),
             ("Arrays & Lists", "fixed vs growing", "▣", GREEN),
             ("Loops & if", "for, while, switch", "↻", GREEN),
             ("Exceptions & files", "try, catch, finally", "⚠", GREEN),
             ("Enums", "fixed values", "≡", PURPLE),
             ("Lambdas & sorting", "(a, b) -> ...", "λ", PURPLE),
             ("Threads", "synchronized", "⚙", PURPLE)],
             ats=[1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4], y0=230, gap=168)),
        ("end", "", ["Now open the code, change something, and run it again.", "That is the best way to learn Java."],
         L_title("Now it's your turn", "Open the code, change something, and run it again.",
                 "javac -d out ...   •   java -cp out clinic.app.Main")),
    ]


def L_title(title, sub, small=None):
    cup = mv.badge("☕", 200, SAFFRON, NAVY)
    els = [El(cup, center_x(cup), 190, slide=0)]
    t = mv.text_img(title, 110, "black", align="center")
    els.append(El(t, center_x(t), 440))
    s = mv.text_img(sub, 46, "light", SOFT, max_w=1400, align="center")
    els.append(El(s, center_x(s), 600))
    if small:
        sm = mv.text_img(small, 32, "semi", SAFFRON, align="center")
        els.append(El(sm, center_x(sm), 760, t=1.2))
    return els


def L_grid3(heading, items, ats, y0=260, gap=176, footer=None):
    els = mv.L_heading(heading)
    cols = 3
    w = (mv.W - 240 - 50 * (cols - 1)) // cols
    for i, (title, body, ic, col) in enumerate(items):
        card = mv.rounded((w, 136), 22, CARD + (255,))
        card.alpha_composite(mv.badge(ic, 84, col, NAVY), (24, 26))
        d = ImageDraw.Draw(card)
        d.text((130, 22), title, font=mv.font(38, "bold"), fill=WHITE)
        d.text((132, 76), body, font=mv.font(28), fill=SOFT)
        els.append(El(card, 120 + (i % cols) * (w + 50), y0 + (i // cols) * gap, at=ats[i]))
    if footer:
        f = mv.text_img(footer[0], 54, "bold", SAFFRON, align="center")
        els.append(El(f, center_x(f), y0 + ((len(items) + cols - 1) // cols) * gap + 40, at=footer[1]))
    return els


# ---------------------------------------------------------------- voice

def spoken(s: str) -> str:
    """Text for the voice: read code words the way a teacher says them."""
    s = s.replace("javac", "java-C").replace("-cp", "dash C P").replace("-d out", "dash D out")
    s = s.replace("MAX_SLOTS", "max slots").replace(".java", " dot java").replace(".class", " dot class")
    s = s.replace("println", "print line").replace("()", "")
    s = re.sub(r"\bD(\d)-S(\d)\b", r"D \1, S \2", s)
    s = re.sub(r"\bd(\d)-s(\d)\b", r"d \1, s \2", s)
    s = re.sub(r"\b([PA])(\d{4})\b", r"\1 \2", s)
    s = re.sub(r"(?<=\w)\.(?=\w)", " dot ", s)
    s = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", s)  # camelCase -> separate words
    return s.replace("JVM", "J V M")


async def _tts(text, path):
    c = mv.edge_tts.Communicate(text, mv.VOICE, rate="+4%")
    with open(path, "wb") as f:
        async for ch in c.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])


if __name__ == "__main__":
    mv.beats, mv.spoken, mv._tts = beats, spoken, _tts
    mv.main(*sys.argv[1:4])
