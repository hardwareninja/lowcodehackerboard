#!/usr/bin/env python3

import sys
import six
import base64

PAYLOAD = "Payload"
FILENAME = "filename"
COMMAND = "command"
SCRIPT = "script"

MAXLENGTH = 8191

OUTPUT = "payload"
EXT = ".%02i"
ECHO = "echo %s >>" + OUTPUT + EXT + "\n"
COPY = "copy /b %s " + OUTPUT + ".txt\n"

def wrap(s, w):
    return [s[i:i + w] for i in range(0, len(s), w)]

def echoEsc(s):
    escaped = s.replace("\t", "\x20"*4)
    escaped = escaped.replace("^", "^^")
    escaped = escaped.replace("&", "^&")
    escaped = escaped.replace("|", "^|")
    escaped = escaped.replace(">", "^>")
    escaped = escaped.replace("<", "^<")
    return escaped

def getFilename():
    try:
        with open(FILENAME, "r") as f:
            filename = f.read()
            return filename.strip()
    except:
        return None

def getCommand():
    try:
        with open(COMMAND, "r") as f:
            command = f.read()
            return command
    except:
        return None

def getScript():
    try:
        with open(SCRIPT, "r") as f:
            script = f.read()
            return script.strip()
    except:
        return None

def readBinary(filename):
    try:
        with open(filename, "rb") as f:
            binary = f.read()
            return binary
    except:
        return None

def writePayload(encoded):
    try:
        with open(PAYLOAD, "w") as f:
            i = 0
            payload = ""
            length = len(ECHO % (payload, i))
            chunks = wrap(encoded, MAXLENGTH - length)
            for chunk in chunks:
                payload += ECHO % (chunk, i)
                i += 1
            p = ""
            for n in range(0, i):
                if n > 0:
                    p += "+"
                p += OUTPUT + EXT % (n)
            payload += COPY % (p)
            f.write(payload)
    except Exception as e:
        print(e)

def copyScript(script):
    try:
        with open(script, "r") as read:
            lines = read.readlines()
        with open(PAYLOAD, "a") as write:
            for line in lines:
                line = echoEsc(line.strip("\n"))
                if line.strip() == "":
                    continue
                echo = ECHO.replace(OUTPUT + EXT, script)
                write.write(echo % (line))
    except Exception as e:
        print(e)

def printCommand(command):
    try:
        with open(PAYLOAD, "a") as f:
            lines = command.split("\n")
            for line in lines:
                f.write(line + "\n")
    except Exception as e:
        print(e)

def main():
    filename = None
    command = None
    script = None
    
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    if len(sys.argv) > 2:
        command = sys.argv[2]
    if len(sys.argv) > 3:
        script = sys.argv[3]

    if not filename:
        filename = getFilename()
    if not command:
        command = getCommand()
    if not script:
        script = getScript()

    if filename:
        binary = readBinary(filename)
        if binary:
            encoded = base64.b64encode(binary)
            writePayload(encoded.decode("UTF-8"))

    if script:
        copyScript(script)

    if command:
        printCommand(command)

if __name__ == "__main__":
    main()
