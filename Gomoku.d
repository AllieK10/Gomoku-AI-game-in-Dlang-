import std.stdio;
import std.conv;
import player;
import std.algorithm;
import std.socket;

/*struct Position
{
    uint i, j; //ith row, jth column
}   
struct Direction
{
    int i, j;
}
*/

class Game 
{

    IPlayer[2] players;

    char[15][15] field;
    char current;// x 0

    this (IPlayer p1, IPlayer p2)
    {
        players[0] = p1;
        players[1] = p2;
    }

    void printField()
    {
        write(" ");
        for (int i = 0; i < 15; i++)
        {
            write("|");
            write(to!char('A' + i));
        }  
        write("|");
        writeln(); 
        write("-|"); 
        for(int i = 0; i < 15; i++)
        {
          write("-+");
        }
        writeln();
        for(int i = 0; i < 15; i++)
        {
            for(int j = 0; j < 16; j++)
            {
                if (j == 0)
                {
                    write(to!char('A' + i));
                    write("|"); 
                }
                else 
                {
                    write(field[i][j-1], "|");
                }
            } 
            writeln();
            for(int j = 0; j < 16; j++)
            {
               write("-+");
            }
            writeln();
        }
    }

    void setInput(Position pos)
    {
        field[pos.i][pos.j] = current;
        players[1].write(pos);
    }
    
  /*  Position playerInput()
    {
        do
        {
            char i, j;
            write("Player: ", current);
            write(" Coordinates: ");
            readf(" %s %s\n", i, j);

            Position pos;
            pos.i = (i - 'A');
            pos.j = (j - 'A');
    
            if ((pos.i >= 15) || (pos.j >= 15))
            {
                write("Invalid input\n");
            }
            else
            {
                return pos;
            }
        }
        while (true);
    }
    */
    bool gameOver(Position pos)
    {
        Direction[] allDirections = [Direction(0,1), Direction(1,1), Direction(-1,1), Direction(1,0)];
        auto cellsByDirection(Position pos, Direction d)
        {
            return indeciesByDirection(pos, d, 4).map!(p => field[p.i][p.j]);
        }
        bool ended = allDirections.any!(d => cellsByDirection(pos,d).hasSequence(current, 5));  
        return ended;
    }    
    
}

void main(string[] args) 
{
    IPlayer p1;
    IPlayer p2;

    if (args[1] == "server")
    {
        auto serv = new TcpSocket();
        serv.bind(new InternetAddress("127.0.0.1", 7000));
        serv.listen(10);
        auto sock1 = serv.accept();
        auto sock2 = serv.accept();
        p1 = new RemotePlayer(sock1);
        p2 = new RemotePlayer(sock2);
        sock1.send("X\r\n");
        sock2.send("O\r\n");
    }
    else if (args[1] == "client")
    {
        TcpSocket sock = new TcpSocket(new InternetAddress("127.0.0.1", 7000));
        char[3] buf;
        sock.receive(buf);
        write(buf);
 
        if(buf[0] == 'O')
        {
            p1 = new RemotePlayer(sock);
            p2 = new ConsolePlayer;
        } 
        else 
        {
            p2 = new RemotePlayer(sock);
            p1 = new ConsolePlayer;
        }
    }
    else if (args[1] == "artint")
    {
            p1 = new ArtIntel;
            p2 = new ConsolePlayer;
    }
    else if (args[1] == "artintremote")
    {
        TcpSocket sock = new TcpSocket(new InternetAddress("192.168.230.191", 7000));
        char[3] buf;
        sock.receive(buf);
        write(buf);
 
        if(buf[0] == 'O')
        {
            p1 = new RemotePlayer(sock);
            p2 = new ArtIntel;
        } 
        else 
        {
            p2 = new RemotePlayer(sock);
            p1 = new ArtIntel;
        }
    }
   
    Game game = new Game(p1, p2);

    OUTER:while(true)
    {
        //string S;
        //readf("%s\n", S);
        foreach(char c; ['X', 'O']) //[IPlayer p1, IPlayer p2]
        {
            game.current = c; 
            game.printField();
            auto input = game.players[0].read();  //auto input = players[0].read();
          
            game.setInput(input);//players[1].write(input);
            
            //check if the game is over
            game.gameOver(input);
            swap(game.players[0], game.players[1]);
            if (game.gameOver(input) == true)
            {
                writef("Winner is %s!", c);
                writeln(); 
                break OUTER;
            }
        }  
    }
}

bool hasSequence(Range, V)(Range r, V val, size_t target)//if there's a sequence of a certain value several times in a row
{
    int counter;
    foreach(v;r)
    {
        if(v == val)
        {
            counter++;
            if(counter == target)
            {
                return true;
            }
        }
        else 
        {
            counter = 0;
        }
    }
    return false;
} 



unittest
{
    assert([1,5,5,5,2].hasSequence(5,3));
    foreach(v; MyRange(Position(0,4), Position(10,14), Direction(1, 1)))
    {
        writeln(v);
    }
}


/* 
struct Estimate 
{
    Position turn; //whose and what turn it is now
    double value; 
}


alias State = Cell[15][15];

double estimate(ref State field);
auto allAvailableTurns(ref State field);

Cell opposite(Cell c)
{
    if (c == Cell.X) return Cell.O;
    else return Cell.X;
}

Estimate minimax(ref State field, Cell cur, uint depth)
{
    {
        if (depth == 0) return Estimate (Position(0,0), estimate(field));
    }

    Estimate halfTurn(Position pos)
    {
        field[pos.i][pos.j] = cur;
        Estimate res = minimax(field, opposite(cur), depth-1);
        field[pos.i][pos.j] = Cell.NONE;
        return Estimate(pos, res.value);
    }

    Estimate best(Estimate a, Estimate b)
    {
        return ((a.value > b.value) == (cur == Cell.X)) ? a : b;
    }

    double initVal = (cur == Cell.X) ? - double.infinity:double.infinity;

    return allAvailableTurns(field)
        .map!halfTurn
        .fold!best(Estimate(Position(0,0), initVal));
}
*/


unittest
{
    assert(readMessage([]) == []);
    writeln(readMessage(["1\r\n"]));
    assert(readMessage(["1\r\n"]) == ["1"]);
    assert(readMessage(["1","\r\n"]) == ["1"]);
    assert(readMessage(["1", "2", "3","\r\n"]) == ["123"]);
    assert(readMessage(["1","\r\n", "2\r\n"]) == ["1", "2"]);
}
