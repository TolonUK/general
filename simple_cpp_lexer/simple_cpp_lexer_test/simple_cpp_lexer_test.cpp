#include "..\simple_cpp_lexer.hpp"
#include <iostream>
#include <fstream>

using namespace std;
using namespace simple_cpp_lexer_spirit;

struct standard_action
{
	standard_action(const char* name, ostream& o) : m_name(name), m_out(o) { }

    template <typename T>
    void operator()(T a) const
    {
		m_out << m_name << ": " << a << endl;
    }

    template <typename IteratorT>
    void operator()(IteratorT first, IteratorT last) const
    {
		m_out << m_name << ": ";
		while (first != last)
            m_out << *first++;
		m_out << endl;
    }

private:
	std::string m_name;
	ostream& m_out;
};

struct my_actions
{
	my_actions(ostream& o) : 
		m_out(o), 
		preprocessor("preprocessor", o),
		comment("comment", o),
		keyword("keyword", o),
		identifier("identifier", o),
		special("special", o),
		string("string", o),
		literal("literal", o),
		number("number", o),
		unexpected("unexpected", o)
	{ }

	standard_action preprocessor;
	standard_action comment;
	standard_action keyword;
	standard_action identifier;
	standard_action special;
	standard_action string;
	standard_action literal;
	standard_action number;
	standard_action unexpected;

private:
	ostream& m_out;
};

int parse(istream& in, ostream& out)
{
    in.unsetf(ios::skipws); //  Turn off white space skipping on the stream

    vector<char> vec;
    std::copy(
        istream_iterator<char>(in),
        istream_iterator<char>(),
        std::back_inserter(vec));

	//out << "Error Code Harvester" << endl << endl;

	vector<char>::const_iterator first = vec.begin();
    vector<char>::const_iterator last = vec.end();

    my_actions actions(out);
    simple_cpp_lexer<my_actions> p(actions);
    parse_info<vector<char>::const_iterator> info =
        parse(first, last, p);

    if (!info.full)
    {
        cerr << "parsing error\n";
        cerr << string(info.stop, last);
        return -1;
    }

    return 0;
}

int main()
{
	ifstream ifs("simple_cpp_lexer.hpp");
	parse(ifs, cout);
}
