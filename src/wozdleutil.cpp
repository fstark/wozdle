#include <iostream>
#include <fstream>
#include <string>
#include <vector>

const int base = 32;
const int deltaa = 1;   //  Is 'a' coded as 0 or 1?

std::string base32ToString(int number) {
    std::string result;
    
    for (int i = 0; i < 5; ++i) {
        char c = 'a' + (number % base)-deltaa;
        result = c + result;
        number /= base;
    }
    
    return result;
}

int base32Number(const std::string& word) {
    int number = 0;
    
    for (char c : word) {
        if (c >= 'a' && c <= 'z') {
            number = number * base + (c - 'a')+deltaa;
        }
    }
    
    return number;
}

int main() {
    std::vector<std::string> lines;  // Vector to store lines
    std::vector<int> words;  // Vector to store lines

    printf( "; apple = %08x (%d)\n", base32Number( "apple" ), base32Number( "apple" ) );
    printf( "; steve = %08x (%d)\n", base32Number( "steve" ), base32Number( "steve" ) );
    printf( "; ooooo = %08x (%d)\n", base32Number( "ooooo" ), base32Number( "ooooo" ) );
    printf( "; zzzzz = %08x (%d)\n", base32Number( "zzzzz" ), base32Number( "zzzzz" ) );
    printf( "; ppppp = %08x (%d)\n", base32Number( "ppppp" ), base32Number( "ppppp" ) );

    // Open the file
    std::ifstream file("data/vocabulary.txt");

    // Check if the file is open
    if (!file.is_open()) {
        std::cerr << "Error opening file." << std::endl;
        return 1;
    }

    std::string line;
    // Read each line and store in the vector
    while (std::getline(file, line)) {
        lines.push_back( line );
        words.push_back( base32Number(line) );
    }

    // Close the file
    file.close();

    printf( "VOCABULARY:\n" );

    int count = 0;
    int current = 0;
    for (int i=0;i!=words.size()-1;i++)
    {
        int delta = words[i]-current;
        current = words[i];
        if (delta<128)
        {
            count++;
            printf( ".byte $%02X", delta );
            printf( " ; %s\n", base32ToString(words[i]).c_str() );
        }
        else if (delta<16384)
        {
            count+=2;
            delta += (1<<15);
            printf( ".byte $%02X,$%02X", delta>>8, delta%256 );
            printf( " ; %s\n", base32ToString(words[i]).c_str() );
        }
        else
        {
            count+=3;
            delta += (1<<23)+(1<<22);
            printf( ".byte $%02X,$%02X,$%02X", delta>>16, (delta>>8)%256, delta%256 );
            printf( " ; %s\n", base32ToString(words[i]).c_str() );
        }
        // std::cout << delta << " ";
        // if (delta>100000)
        //     std::cout << "(" << base32ToString( words[i] ) << " " << base32ToString( words[i+1] ) << ") ";
    }

    int delta = base32Number("zzzzz")+1-words.back();
    delta += (1<<23)+(1<<22);
    printf( ".byte $%02X,$%02X,$%02X", delta>>16, (delta>>8)%256, delta%256 );
    printf( " ; go past zzzzz\n" );

    std::cout << "\n" << "\n; bytes " << count << "\n"; // ... no ':1' in comment or assembly fails...

    return 0;
}

/*
    WRD2NUM : Converts a 5 bytes word into a 4 bytes number (25 bits)
    NUM2WRD : Converts a 4 bytes number into a 5 bytes word
    ADD32   : Adds two 4 bytes number together
    UNPACK  : Converts a 1, 2 or 3 bytes number into a 4 bytes number. Advance the pointer.
*/
