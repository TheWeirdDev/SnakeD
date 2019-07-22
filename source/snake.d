import std.string;
import std.random;
import std.datetime;
import std.conv;

struct SnakePart {
    int x, y;
    immutable(char)* b;
}
enum Direction {UP = 0, DOWN, LEFT, RIGHT}

struct Snake {
    SnakePart[] parts;
    Direction dir;
    private int width, height;

    @property ref SnakePart head() {
        return parts[0];
    }

    this(int width, int height) {
        auto ut = Clock.currTime().toUnixTime();
        auto rnd = Random(cast(uint) ut);

        auto dir = uniform(0, 4, rnd);
        this.dir =  to!Direction(dir);
        this.width = width;
        this.height = height;

        reset();
    }

    private void resetParts(int width, int height) {
        auto centerw = width/2;
        auto centerh = height/2;

        parts ~= SnakePart(centerh, centerw, "#".toStringz);
        int wPos, hPos;
        final switch(dir) {
            case Direction.LEFT:
                wPos = 1;
                break;
            case Direction.RIGHT:
                wPos = -1;
                break;
            case Direction.UP:
                hPos = 1;
                break;
             case Direction.DOWN:
                hPos = -1;
                break;
        }

        for (int i = 1; i < 4; i++) {
            parts ~= SnakePart(centerh+i*hPos, centerw+i*wPos, "*".toStringz);
        }
    }

    void reset() {
        parts.length=0;
        resetParts(width, height);
    }
}