
import sys

def main():
    width = 512
    height = 512
    sys.stdout.write("P3 %d %d 255\n" % (width, height))

    for y in range(height):
        for x in range(width):
            red = 0
            green = 0
            blue = 0

            red = (x / 10 * 10) % 256
            green = (y / 10 * 10) % 256

            sys.stdout.write("%d %d %d " % (red, green, blue))

main()
