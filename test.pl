#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use WikiDOM::Mediawiki::PreprocessorStack;
use WikiDOM::Mediawiki::PreprocessorPart;
use WikiDOM::Mediawiki::PhpStrings;

#use Carp::Always;

my $text = '=================


==123==
Some paragraph


Second
multiline
parapraph

{{test|test}}'; # В теории должны получать в качестве параметра функции
my $flags = 0; # shift || 0


my $rules = { "{" => { 'end' => '}',                        # } {  -- for stupid highlighter
                      'names' => { 2 => 'template',
                                   3 => 'tplarg',
                                 },
                       'min' => 2,
                       'max' => 3,
                     },
             '[' => {
                      'end' => ']',
                      'names' => {},
                      'min' => 2,
                      'max' => 2,
                     }
           };

my $enableOnlyinclude = 0; # $enableOnlyinclude = false;


#my $xmlishRegex = implode( '|', array_merge( $xmlishElements, $ignoredTags ) );

#// Use "A" modifier (anchored) instead of "^", because ^ doesn't work with an offset
#my $elementsRegex = "~($xmlishRegex)(?:\s|\/>|>)|(!--)~iA";

my $stack = new WikiDOM::Mediawiki::PreprocessorStack();
my $searchBase = "[{<\n"; #}
my $revText = strrev( $text );  #// For fast reverse searches
my $lengthText = strlen( $text );

my $i = 0;                     # Input pointer, starts out pointing to a pseudo-newline before the start
my $accum = $stack->getAccum();   # Current accumulator
$$accum = '<root>';

my $findEquals = undef;            # True to find equals signs in arguments
my $findPipe = undef;              # True to take notice of pipe characters
my $headingIndex = 1;
my $inHeading = 0;                 # True if $i is inside a possible heading
my $findOnlyinclude = $enableOnlyinclude; # True to ignore all input up to the next <onlyinclude>
my $fakeLineStart = 1;     # Do a line-start run without outputting an LF character


# These variables are not defined in original php code, just used in some places.  
# But since in php all variables are function-wide wisible, and we are using strinct, we should strictly define them here
my $found = undef;
my $curChar = undef;
my $search;
my $currentClosing;
my $literalLength;
my $rule;
my $matches;
#
my $count;
my $piece;
my $part;
my $wsLength;
my $searchStart;
my $equalsLength;
my $element;

while ()
{
print "=======\n";
print "i = $i \n";
print "accum = ".$$accum."\n";
print "=======\n";

			if ( $fakeLineStart ) {
				$found = 'line-start';
				$curChar = '';
			} else {
				# Find next opening brace, closing brace or pipe
				$search = $searchBase;
				if ( ! defined $stack->top ) {   #if ( $stack->top === false ) {
					$currentClosing = '';
				} else {
					$currentClosing = $stack->top->close;
					$search .= $currentClosing;
				}
				if ( $findPipe ) {
					$search .= '|';
				}
				if ( $findEquals ) {
					#// First equals will be for the template
					$search .= '=';
				}
				$rule = undef; # $rule = null;
				# Output literal section, advance input counter
				$literalLength = strcspn( $text, $search, $i );
				if ( $literalLength > 0 ) {
					$$accum .=  htmlspecialchars( substr( $text, $i, $literalLength ) );
					$i += $literalLength;
				}
				if ( $i >= $lengthText ) {
					if ( $currentClosing eq "\n" ) {
						#// Do a past-the-end run to finish off the heading
						$curChar = '';
						$found = 'line-end';
					} else {
						# All done
						last; #break;
					}
				}  else {
					$curChar = substr($text,$i,1);  #$curChar = $text[$i];
					if ( $curChar eq '|' ) {
						$found = 'pipe';
					} elsif ( $curChar eq '=' ) {
						$found = 'equals';
					} elsif ( $curChar eq '<' ) {
						$found = 'angle';
					} elsif ( $curChar eq "\n" ) {
						if ( $inHeading ) {
							$found = 'line-end';
						} else {
							$found = 'line-start';
						}
					} elsif ( $curChar eq $currentClosing ) {
						$found = 'close';
					} elsif ( defined( $rules->{$curChar} ) ) {  #} elsif ( isset( $rules[$curChar] ) ) {
						$found = 'open';
						$rule = $rules->{$curChar};  # $rule = $rules[$curChar];
					} else {
						# Some versions of PHP have a strcspn which stops on null characters
						# Ignore and continue
						++$i;
						next; # continue;
					}
				}
			}
=cut
			if ( $found == 'angle' ) {
				$matches = false;
				// Handle </onlyinclude>
				if ( $enableOnlyinclude && substr( $text, $i, strlen( '</onlyinclude>' ) ) == '</onlyinclude>' ) {
					$findOnlyinclude = true;
					continue;
				}

				// Determine element name
				if ( !preg_match( $elementsRegex, $text, $matches, 0, $i + 1 ) ) {
					// Element name missing or not listed
					$accum .= '&lt;';
					++$i;
					continue;
				}
				// Handle comments
				if ( isset( $matches[2] ) && $matches[2] == '!--' ) {
					// To avoid leaving blank lines, when a comment is both preceded
					// and followed by a newline (ignoring spaces), trim leading and
					// trailing spaces and one of the newlines.

					// Find the end
					$endPos = strpos( $text, '-->', $i + 4 );
					if ( $endPos === false ) {
						// Unclosed comment in input, runs to end
						$inner = substr( $text, $i );
						$accum .= '<comment>' . htmlspecialchars( $inner ) . '</comment>';
						$i = $lengthText;
					} else {
						// Search backwards for leading whitespace
						$wsStart = $i ? ( $i - strspn( $revText, ' ', $lengthText - $i ) ) : 0;
						// Search forwards for trailing whitespace
						// $wsEnd will be the position of the last space (or the '>' if there's none)
						$wsEnd = $endPos + 2 + strspn( $text, ' ', $endPos + 3 );
						// Eat the line if possible
						// TODO: This could theoretically be done if $wsStart == 0, i.e. for comments at
						// the overall start. That's not how Sanitizer::removeHTMLcomments() did it, but
						// it's a possible beneficial b/c break.
						if ( $wsStart > 0 && substr( $text, $wsStart - 1, 1 ) == "\n"
							&& substr( $text, $wsEnd + 1, 1 ) == "\n" )
						{
							$startPos = $wsStart;
							$endPos = $wsEnd + 1;
							// Remove leading whitespace from the end of the accumulator
							// Sanity check first though
							$wsLength = $i - $wsStart;
							if ( $wsLength > 0 && substr( $accum, -$wsLength ) === str_repeat( ' ', $wsLength ) ) {
								$accum = substr( $accum, 0, -$wsLength );
							}
							// Do a line-start run next time to look for headings after the comment
							$fakeLineStart = true;
						} else {
							// No line to eat, just take the comment itself
							$startPos = $i;
							$endPos += 2;
						}

						if ( $stack->top ) {
							$part = $stack->top->getCurrentPart();
							if ( ! (isset( $part->commentEnd ) && $part->commentEnd == $wsStart - 1 )) {
								$part->visualEnd = $wsStart;
							}
							// Else comments abutting, no change in visual end
							$part->commentEnd = $endPos;
						}
						$i = $endPos + 1;
						$inner = substr( $text, $startPos, $endPos - $startPos + 1 );
						$accum .= '<comment>' . htmlspecialchars( $inner ) . '</comment>';
					}
					continue;
				}
				$name = $matches[1];
				$lowerName = strtolower( $name );
				$attrStart = $i + strlen( $name ) + 1;

				// Find end of tag
				$tagEndPos = $noMoreGT ? false : strpos( $text, '>', $attrStart );
				if ( $tagEndPos === false ) {
					// Infinite backtrack
					// Disable tag search to prevent worst-case O(N^2) performance
					$noMoreGT = true;
					$accum .= '&lt;';
					++$i;
					continue;
				}

				// Handle ignored tags
				if ( in_array( $lowerName, $ignoredTags ) ) {
					$accum .= '<ignore>' . htmlspecialchars( substr( $text, $i, $tagEndPos - $i + 1 ) ) . '</ignore>';
					$i = $tagEndPos + 1;
					continue;
				}

				$tagStartPos = $i;
				if ( $text[$tagEndPos-1] == '/' ) {
					$attrEnd = $tagEndPos - 1;
					$inner = null;
					$i = $tagEndPos + 1;
					$close = '';
				} else {
					$attrEnd = $tagEndPos;
					// Find closing tag
					if ( preg_match( "/<\/" . preg_quote( $name, '/' ) . "\s*>/i",
							$text, $matches, PREG_OFFSET_CAPTURE, $tagEndPos + 1 ) )
					{
						$inner = substr( $text, $tagEndPos + 1, $matches[0][1] - $tagEndPos - 1 );
						$i = $matches[0][1] + strlen( $matches[0][0] );
						$close = '<close>' . htmlspecialchars( $matches[0][0] ) . '</close>';
					} else {
						// No end tag -- let it run out to the end of the text.
						$inner = substr( $text, $tagEndPos + 1 );
						$i = $lengthText;
						$close = '';
					}
				}
				// <includeonly> and <noinclude> just become <ignore> tags
				if ( in_array( $lowerName, $ignoredElements ) ) {
					$accum .= '<ignore>' . htmlspecialchars( substr( $text, $tagStartPos, $i - $tagStartPos ) )
						. '</ignore>';
					continue;
				}

				$accum .= '<ext>';
				if ( $attrEnd <= $attrStart ) {
					$attr = '';
				} else {
					$attr = substr( $text, $attrStart, $attrEnd - $attrStart );
				}
				$accum .= '<name>' . htmlspecialchars( $name ) . '</name>' .
					// Note that the attr element contains the whitespace between name and attribute,
					// this is necessary for precise reconstruction during pre-save transform.
					'<attr>' . htmlspecialchars( $attr ) . '</attr>';
				if ( $inner !== null ) {
					$accum .= '<inner>' . htmlspecialchars( $inner ) . '</inner>';
				}
				$accum .= $close . '</ext>';
			} elseif ( $found == 'line-start' ) {
=cut
if ( $found eq 'line-start' ) {
				#// Is this the start of a heading?
				#// Line break belongs before the heading element in any case
				if ( $fakeLineStart ) {
					$fakeLineStart = 0;  # $fakeLineStart = false;
				} else {
					$$accum .= $curChar;
					$i++;
				}
				$count = strspn( $text, '=', $i, 6 );
				if ( $count == 1 && $findEquals ) {
					#// DWIM: This looks kind of like a name/value separator
					#// Let's let the equals handler have it and break the potential heading
					#// This is heuristic, but AFAICT the methods for completely correct disambiguation are very complex.
				} elsif ( $count > 0 ) {
					$piece = { # array(
						'open' => "\n",
						'close' => "\n",
						'parts' => [ new WikiDOM::Mediawiki::PreprocessorPart('=' x $count)  ], # array( new PPDPart( str_repeat( '=', $count ) ) ),
						'startPos' => $i,
						'count' => $count }; # );
					$stack->push( $piece );
					$accum = $stack->getAccum();
					$flags = $stack->getFlags();
					$findEquals = $flags->{findEquals}; # extract( $flags );
					$findPipe = $flags->{findPipe}; # extract( $flags );
					$inHeading = $flags->{inHeading}; # extract( $flags );
					$i += $count;
				}
			} elsif ( $found eq 'line-end' ) {
				$piece = $stack->top;
				#// A heading must be open, otherwise \n wouldn't have been in the search list
				warn '$piece->open eq "\n"' unless $piece->open eq "\n";        # assert( '$piece->open == "\n"' );
				$part = $piece->getCurrentPart();
				#// Search back through the input to see if it has a proper close
				#// Do this using the reversed string since the other solutions (end anchor, etc.) are inefficient
				$wsLength = strspn( $revText, " \t", $lengthText - $i );
				$searchStart = $i - $wsLength;
				if ( isset( $part->commentEnd ) && $searchStart - 1 eq $part->commentEnd ) {
					#// Comment found at line end
					#// Search for equals signs before the comment
					$searchStart = $part->visualEnd;
					$searchStart -= strspn( $revText, " \t", $lengthText - $searchStart );
				}
				$count = $piece->count;
				$equalsLength = strspn( $revText, '=', $lengthText - $searchStart );
				if ( $equalsLength > 0 ) {
					if ( $searchStart - $equalsLength == $piece->startPos ) {
						#// This is just a single string of equals signs on its own line
						#// Replicate the doHeadings behaviour /={count}(.+)={count}/
						#// First find out how many equals signs there really are (don't stop at 6)
						$count = $equalsLength;
						if ( $count < 3 ) {
							$count = 0;
						} else {
							$count = min( 6, intval( ( $count - 1 ) / 2 ) );
						}
					} else {
						$count = min( $equalsLength, $count );
					}
					if ( $count > 0 ) {
						#// Normal match, output <h>
						$element = "<h level=\"$count\" i=\"$headingIndex\">$$accum</h>";
						$headingIndex++;
					} else {
						#// Single equals sign on its own line, count=0
						$element = $accum;
					}
				} else {
					#// No match, no <h>, just pass down the inner text
					$element = $accum;
				}
				#// Unwind the stack
				$stack->pop();
				$accum = $stack->getAccum();
				$flags = $stack->getFlags();
				$findEquals = $flags->{findEquals}; # extract( $flags );
				$findPipe = $flags->{findPipe}; # extract( $flags );
				$inHeading = $flags->{inHeading}; # extract( $flags );
#
#				#// Append the result to the enclosing accumulator
				$$accum .= $element;
#				#// Note that we do NOT increment the input pointer.
#				#// This is because the closing linebreak could be the opening linebreak of
#				#// another heading. Infinite loops are avoided because the next iteration MUST
#				#// hit the heading open case above, which unconditionally increments the
#				#// input pointer.
#			} elsif ( $found == 'open' ) {

			}
last if $i>=length($text);
  last if $i>1000;  # foolproof for now
  $i++;
}


# clones of some native php functions to make parser code more similar to original php code


sub htmlspecialchars
{
  my $string = shift;
  warn 'htmlspecialchars does not suppport any additional parametrs, exept first one.' unless @_;
  $string =~ s/&/&amp;/gs;
  $string =~ s/"/&quot;/gs; #"
#  $string =~ s/'/&#039;/gs; #" #should not do it unless flag ENT_QUOTES is set, but flugs are not supported, so do nothing
  $string =~ s/</&lt;/gs; 
  $string =~ s/>/&gt;/gs; 
  return $string;
}

sub isset
{
  return defined shift;
}

sub min
{
  my @l = @_;
  my $min = $l[0];
  foreach my $el (@l)
  {
    $min = $el if $el<$min;
  }
  return $min;
}
sub intval
{
  return int(shift);
}