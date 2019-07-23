import deimos.ncurses;
import std.string;
import core.sys.posix.unistd;
import snake;
import std.random;
static import std.datetime;

enum SIGWINCH = 28;
extern(C) void signal(int sig, void function(int) );

private WINDOW* win;
private int score = 0;
private Snake mySnake;
private bool gameOver = false;
private bool won = false;
enum HEIGHT = 15, WIDTH = 45;

struct Food {
    int x,y;
    bool showing;
}
private Food food;

private void printGame() {
    foreach (ref part; mySnake.parts) {
        mvwprintw(win, part.x, part.y, part.b);
    }
    for (size_t i = mySnake.parts.length - 1; i > 0 ; i--) {
        mySnake.parts[i].x =  mySnake.parts[i-1].x;
        mySnake.parts[i].y =  mySnake.parts[i-1].y;
    }
    final switch(mySnake.dir){
        case Direction.UP:
            mySnake.head.x--;
            break;
        case Direction.DOWN:
            mySnake.head.x++;
            break;
        case Direction.LEFT:
            mySnake.head.y--;
            break;
        case Direction.RIGHT:
            mySnake.head.y++;
            break;
    }
    if (mySnake.head.x < 1) {
        mySnake.head.x = HEIGHT -2 ;
    } else if (mySnake.head.x > HEIGHT -2) {
        mySnake.head.x = 1;
    }

    if (mySnake.head.y < 1) {
        mySnake.head.y = WIDTH - 2;
    } else if (mySnake.head.y > WIDTH -2) {
        mySnake.head.y = 1;
    }

    won = mySnake.parts.length == (HEIGHT-2)*(WIDTH-2);
    if (won)
        return;

    if (!food.showing)
        putFood();

    mvwprintw(win, food.x, food.y, "+");

    checkCollision();

}

private long getCharAt(int x, int y) {
    return mvwinch(win, x, y) & 0xff;
}

void putFood(){
    long what;
    int x, y;

    auto ut = std.datetime.Clock.currTime().toUnixTime();
    auto rnd = Random(cast(uint) ut);
    do {
        x = uniform(1, HEIGHT-1, rnd);
        y = uniform(1, WIDTH-1, rnd);
        what = getCharAt(x, y);
    } while (what != ' ');
    food.x = x;
    food.y = y;
    food.showing = true;
}

private void checkCollision(){
    immutable what = getCharAt(mySnake.head.x, mySnake.head.y);
    if (what == '*') {
        gameOver = true;
        return;
    }
    if (what == '+') {
        score++;
        food.showing = false;
        mySnake.parts ~= SnakePart(mySnake.parts[$-1].x, mySnake.parts[$-1].y, "*");
    }
}

private void showWindow() {
    int x, y;

    refresh();
    clear();
    refresh();
    getmaxyx(stdscr, y, x);
    if (x < WIDTH || y < HEIGHT) {
        printw("Not enough space. Resize your terminal window");
        return;
    }

    bkgd(COLOR_PAIR(1));
    refresh();

    win = newwin(HEIGHT, WIDTH, 1, 2);
    scope(exit) wrefresh(win);

    box(win, 0, 0);
    wbkgd(win, COLOR_PAIR(2));
    mvwprintw(win, 0, 2, "Snake Game".toStringz, x, y);

    wattron(win, COLOR_PAIR(3));
    wattroff(win, COLOR_PAIR(3));
    mvwprintw(win, HEIGHT-1, 2, " Score: %d ".toStringz, score);
    mvwprintw(win, HEIGHT-1, WIDTH-11, " exit = q ".toStringz, score);
    if (gameOver || won) {
          mvwprintw(win, HEIGHT/2, WIDTH/2-5, gameOver ? "Game Over!".toStringz : "You Won !!".toStringz);
          mvwprintw(win,  HEIGHT/2+1, WIDTH/2-5, "Score = %d".toStringz, score);
          mvwprintw(win,  HEIGHT/2+2, WIDTH/2-10, "q to exit, r to restart".toStringz);
          return;
    }
    printGame();
}

extern(C) void sig_handler(int sig_num){
    delwin(win);
    endwin();
    showWindow();
}

void main() {
    initscr();
    noecho();
    nodelay(stdscr, true);

    raw();
    noecho();
    curs_set(0);

    start_color();
    init_pair(1, COLOR_WHITE, COLOR_BLUE);
    init_pair(2, COLOR_BLACK, COLOR_WHITE);
    init_pair(3, COLOR_WHITE, COLOR_RED);
    signal(SIGWINCH, &sig_handler);
    keypad(stdscr,true);

    mySnake = Snake(WIDTH, HEIGHT);

    showWindow();
    while(true){
        int ch = getch();
        if(ch == 'q' || ch == 'Q'){
            delwin(win);
            endwin();
            break;
        } else if (ch == KEY_RIGHT) {
            if (mySnake.dir != Direction.LEFT)
                mySnake.dir = Direction.RIGHT;
        } else if (ch == KEY_LEFT) {
            if (mySnake.dir != Direction.RIGHT)
                mySnake.dir = Direction.LEFT;
        } else if (ch == KEY_UP) {
            if (mySnake.dir != Direction.DOWN)
                mySnake.dir = Direction.UP;
        } else if (ch == KEY_DOWN) {
            if (mySnake.dir != Direction.UP)
                mySnake.dir = Direction.DOWN;
        } else if ((ch == 'r' || ch == 'R') && gameOver) {
            gameOver = false;
            score = 0;
            mySnake.reset();
            putFood();
        }
        usleep(150 * 1000);
        showWindow();
    }
}
