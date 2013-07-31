/*=============================================================================
    Copyright (c) 2002-2004 Joel de Guzman
    http://spirit.sourceforge.net/

    Use, modification and distribution is subject to the Boost Software
    License, Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
    http://www.boost.org/LICENSE_1_0.txt)
=============================================================================*/
#if !defined(SIMPLE_CPP_LEXER_HPP)
#define SIMPLE_CPP_LEXER_HPP

#include <boost/version.hpp>

#if BOOST_VERSION >= 104700
#include <boost/spirit/include/classic_core.hpp>
#include <boost/spirit/include/classic_symbols.hpp>
#include <boost/spirit/include/classic_chset.hpp>
#include <boost/spirit/include/classic_escape_char.hpp>
#include <boost/spirit/include/classic_confix.hpp>
namespace simple_cpp_lexer_spirit = boost::spirit::classic;
namespace boost { namespace spirit { namespace classic {
#else
#include <boost/spirit/core.hpp>
#include <boost/spirit/symbols/symbols.hpp>
#include <boost/spirit/utility/chset.hpp>
#include <boost/spirit/utility/escape_char.hpp>
#include <boost/spirit/utility/confix.hpp>
namespace simple_cpp_lexer_spirit = boost::spirit::repository;
namespace boost { namespace spirit { namespace repository {
#endif

    // simple_cpp_lexer, as its name suggests, is a very simple lexer that
    // recognises c++ lexical entities such as keywords, identifiers,
    // preprocessor directives, etc., and calls user supplied semantic actions
    // per recognized entity. simple_cpp_lexer works on the character level.
    // Be sure to wrap the grammar in a lexeme_d when parsing with a skip
    // parser. See cpp_to_html and quickdoc for applications using this
    // grammar.

    template <typename Actions>
    struct simple_cpp_lexer
        : grammar<simple_cpp_lexer<Actions> >
    {
        simple_cpp_lexer(Actions& actions)
            : actions(actions) {}

        template <typename ScannerT>
        struct definition
        {
            definition(simple_cpp_lexer const& self)
            {
                Actions& actions = self.actions;

                program
                    =  *space_p >>
                       *(   preprocessor    [actions.preprocessor]
                        |   comment         [actions.comment]
                        |   keyword         [actions.keyword]
                        |   identifier      [actions.identifier]
                        |   special         [actions.special]
                        |   string          [actions.string]
                        |   literal         [actions.literal]
                        |   number          [actions.number]
                        |   anychar_p       [actions.unexpected]
                        )
                    ;

                preprocessor
                    =   '#' >> *space_p >> identifier
                    ;

                comment
                    =   +((comment_p("//") | comment_p("/*", "*/"))
                        >> *space_p)
                    ;

                keyword
                    =   keywords >> (eps_p - (alnum_p | '_')) >> *space_p
                    ;   // make sure we recognize whole words only

                keywords
                    =   "and_eq", "and", "asm", "auto", "bitand", "bitor",
                        "bool", "break", "case", "catch", "char", "class",
                        "compl", "const_cast", "const", "continue", "default",
                        "delete", "do", "double", "dynamic_cast",  "else",
                        "enum", "explicit", "export", "extern", "false",
                        "float", "for", "friend", "goto", "if", "inline",
                        "int", "long", "mutable", "namespace", "new", "not_eq",
                        "not", "operator", "or_eq", "or", "private",
                        "protected", "public", "register", "reinterpret_cast",
                        "return", "short", "signed", "sizeof", "static",
                        "static_cast", "struct", "switch", "template", "this",
                        "throw", "true", "try", "typedef", "typeid",
                        "typename", "union", "unsigned", "using", "virtual",
                        "void", "volatile", "wchar_t", "while", "xor_eq", "xor"
                    ;

                special
                    =   +chset_p("~!%^&*()+={[}]:;,<.>?/|\\-") >> *space_p
                    ;

                string
                    =   !as_lower_d['l'] >> confix_p('"', *c_escape_ch_p, '"')
                        >> *space_p
                    ;

                literal
                    =   !as_lower_d['l'] >> confix_p('\'', *c_escape_ch_p, '\'')
                        >> *space_p
                    ;

                number
                    =   (   real_p
                        |   as_lower_d["0x"] >> hex_p
                        |   '0' >> oct_p
                        )
                        >>  *as_lower_d[chset_p("ldfu")]
                        >>  *space_p
                    ;

                identifier
                    =   ((alpha_p | '_') >> *(alnum_p | '_'))
                        >> *space_p
                    ;
            }

            rule<ScannerT>
                program, preprocessor, comment, special, string, literal,
                number, identifier, keyword;

            symbols<>
                keywords;

            rule<ScannerT> const&
            start() const
            {
                return program;
            }
        };

        Actions& actions;
    };

}}} // namespace boost::spirit::repository|classic

#endif // SIMPLE_CPP_LEXER_HPP
