module player; 
import std;

interface IPlayer
{
    Position read();
    void write(Position);
}
struct Position
{
    int i, j; //ith row, jth column
}   
struct Direction
{
    int i, j;
}



class ConsolePlayer: IPlayer
{
    Position read()
    {
         do
        {
            char i, j;
            std.stdio.write("Player: "); 
            std.stdio.write(" Coordinates: ");
            readf(" %s %s\n", i, j);

            Position pos;
            pos.i = (i - 'A');
            pos.j = (j - 'A');
    
            if ((pos.i >= 15) || (pos.j >= 15))
            {
                std.stdio.write("Invalid input\n");
            }
            else
            {
                return pos;
            }
        }
        while (true);
    }

    void write(Position)
    {
        
    }

}

class RemotePlayer: IPlayer
{
    Socket socket;
    string recMessage; //received messages
    string mes; 
    this(Socket socket)
    {
        this.socket = socket;
    }

    Position read()
    {
        auto msg = readMessage();
        writeln(msg.length, " : ", msg.map!(a => cast (int) a));
        if (msg.length < 2)
        {
            return Position(16, 16);
        }
        auto result = Position(cast(uint)msg[0] - cast(uint)'a', cast(uint)msg[1] - cast(uint)'A');
        return result;
    }

    string readMessage()//original ones
    {
     char[16] buffer; 
       // string [] messages;//empty array to fill
        int start; //start point to begin separating messages
        bool rFound = false;
   // foreach (buf[0..size]; message)//to check every single message in array of messages
        while(true)
        {
            if (mes.empty)
            {
                int size = socket.receive(buffer);
                mes = buffer[0..size].idup;
            }
            writeln(mes);
            for (int i = 0; i < mes.length; i++) //separation
            {
                writeln(cast(int) mes[i]);
                if (mes[i] == '\r')
                {
                    writeln("r", i);
                    rFound = true; 
                }
                else if ((mes[i] == '\n') && (rFound))
                {
                    writeln("n", i);
                    //   messages ~= recMessage; //filling empty array with separate messages
            
                    string result = recMessage;
                    recMessage = "";
                    mes = mes[i+1..$];
                    rFound = false; //so that the loop would continue doing its job     
                    return result;
                }
                else 
                {
                    recMessage ~= mes[i];
                    rFound = false;
                }
            //string m = parser.getNext(buf[0..size]);
            }
        }
    }
  
    void write(Position p)
    { 
        char[] msg = "__\r\n".dup;
        msg[0] = cast(char)(p.i + 'a');
        msg[1] = cast(char)(p.j + 'A');
        socket.send(msg);

    }

}  
 
class ArtIntel: IPlayer
{
    char[15][15] field;
    Position[] myturns; //my moves
    Position[] opturns; //opponent's turns
 
   /* Position read()
    {
        int i,j;   
        do
        {
            i = uniform(0,15); //random position in between 0 and 15
            j = uniform(0,15); 
        }
        while(field[i][j] != char.init); //while chosen position is free

            Position pos;
            pos.i = i;
            pos.j = j;
            field[i][j] = 'X'; //put X in there
            myturns~=pos;
      
            return pos;
    }
    */
    
    void write(Position pos)
    {
        field[pos.i][pos.j] = 'O'; //my turn
        opturns~=pos;
    }  

    Position[] freecells(Position[] turns) //iterate through neighbors and return an array of empty cells
    {
        //Position pos;
        Position[] freecells;
        int starti, startj, endi, endj;

        auto cellsByDirection(Position pos, Direction d) 
            {
                return indeciesByOneDirection(pos, d, 4).map!(p => field[p.i][p.j]);
            }
      
        foreach(pos;turns)
        {
            starti = max(pos.i - 1, 0);
            startj = max(pos.j - 1, 0);
            endi = min(pos.i + 1, 14);
            endj = min(pos.j + 1, 14);

             // field[pos.i][pos.j] = symbol; //my current occupied cell
            
            /*   turns[i-1][j-1]  turns[i-1][j]  turns[i-1][j+1]
                turns[i][j-1]    turns[i][j]    turns[i][j+1]   
                turns[i+1][j-1]  turns[i+1][j]  turns[i+1][j+1] 
            */

            for (int i = starti; i < endi + 1; i++) //looking around the currently occupied cell
            {
                for (int j = startj; j < endj + 1; j++)
                {
                    //writeln(i, ",", j, cast(int)field[i][j]);
                    if (field[i][j] == char.init) //if cell is empty
                    {
                        auto d = Direction((i - pos.i).sgn, (j - pos.j).sgn);
                            if (borderDistance(pos, d) < 5) //if border is less than 5 cells away
                            {
                                continue;
                            }
                            if (!cellsByDirection(pos, d).find('O').empty)
                            {
                                continue;
                            }
                        

                        freecells~=Position(i,j); //storing it in the new array
                    }
                }
            } 
        }
        return freecells;
       
    }

    Position[] commoncells(Position[] p1, Position[] p2)//find common cells among both players' free neighbours
    {
        Position[] commoncells;
        IPlayer[2] players;
    
      for (int r = 0; r < p1.length; r++)//iterate through 1st player's neighbours
        {
            for (int c = 0; c < p2.length; c++)//iterate through 2nd player's neighbours
            {
                if (p1[r] == p2[c])
                {
                    commoncells~=p1[r];
                }
            }
        }
        return commoncells;
    }
     
    Position read()
    {
        Position pos; 
        if (myturns.empty == true)
        {
            int i,j;   
            do
            {
                i = uniform(0,15); //random position in between 0 and 15
                j = uniform(0,15); 
            }
            while(field[i][j] != char.init); //while chosen position is free
            pos = Position(i,j);
        }
        else 
        {
            auto myfree = freecells(myturns);
            auto opfree = freecells(opturns);
            auto cells = commoncells(myfree, opfree); 
            writeln(cells, myfree);
            alias preciseEstimate = (Position p, char mySymbol)
            {
                    field[p.i][p.j] = mySymbol;
                    int e = estimate(p, mySymbol);
                    field[p.i][p.j] = char.init;
                    writeln(p,e);
                    return e;
                };

            if (cells.empty == true)
            {
                //pos = myfree.choice;
                pos = myfree.maxElement! (p => preciseEstimate(p, 'X'));
                auto Oppos = myfree.maxElement! (p => preciseEstimate(p, 'O'));
                if (preciseEstimate(pos, 'X') < preciseEstimate(Oppos, 'O'))
                {
                    pos = Oppos;
                }
            }
            else 
            {
                //pos = cells.choice;
                pos = cells.maxElement!(p => preciseEstimate(p, 'X'));
                auto Oppos = cells.maxElement!(p => preciseEstimate(p, 'O'));
                if (preciseEstimate(pos, 'X') < preciseEstimate(Oppos, 'O'))
                {
                    pos = Oppos;
                }
            }
        }
       
        field[pos.i][pos.j] = 'X'; //put X in there
        myturns~=pos;
        return pos;   
    } 


    int estimate(Position pos, char mySymbol) 
    {
       // Position bestPos; //coordinates of the best position among all the empty cells 
        //if number of same symbols in one direction is bigger than in another, return the coordinates of this position as the best option
            
            Direction[] allDirections = [Direction(0,1), Direction(1,1), Direction(-1,1), Direction(1,0), Direction(0,-1),
                                         Direction(-1,-1), Direction(1,-1), Direction(-1,0)];
            auto cellsByDirection(Position pos, Direction d) 
            {
                return indeciesByOneDirection(pos, d, 4).map!(p => field[p.i][p.j]);
            }
            auto numberByDir (Direction d)
            {   
                writeln(pos, d, borderDistance(pos,d));
                return cellsByDirection(pos,d).numberOfSymbols(mySymbol);  
                
            } 

            auto bestDir = allDirections.maxElement!(numberByDir); //among all directions choose one, where there's the biggest number of same symbols in a row

        return numberByDir(bestDir);
    } 

}


auto indeciesByDirection(Position center, Direction dir, uint radius)
{
    uint left = min(radius, borderDistance(center, Direction(-dir.i, -dir.j)));
    uint right = min(radius, borderDistance(center, dir)) + 1;

    return MyRange(Position(center.i - dir.i*left, center.j - dir.j*left),
                            Position(center.i + dir.i*right, center.j + dir.j*right),
                            dir);
}

auto indeciesByOneDirection(Position center, Direction dir, uint radius)
{
    uint right = min(radius, borderDistance(center, dir)) + 1;
    return MyRange(center, Position(center.i + dir.i*right, center.j + dir.j*right), dir);
}

uint borderDistance(uint p, int d)//how far are we from the border
{
    if (d < 0)
    {
        return p;
    }
    else if (d == 0)
    {
        return 14;
    }
    else 
    {
        return 14 - p;
    }
}

uint borderDistance(Position pos, Direction dir)
{
    return min(borderDistance(pos.i, dir.i), borderDistance(pos.j, dir.j));
}

struct MyRange
{
    Position pos;
    Position end;
    Direction dir;
    bool empty()
    {
        return pos == end;
    }
    Position front()
    {
        return pos;
    }
    void popFront()
    {
        pos.i += dir.i;
        pos.j += dir.j;
    }
}

int numberOfSymbols(Range, V)(Range r, V val)//return a number of symbols in a certain direction
    {
        int number; //number of the same symbols
        foreach(v;r)
        {
            if(v == val)
            {
                number++;
            }
            else 
            {
                return number;
            }
        }
        return number;
    } 
