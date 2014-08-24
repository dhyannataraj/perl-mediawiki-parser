package Mediawiki::Preparser;


use strict;
use warnings;
use utf8;

use Storable 'dclone';

use Mediawiki::Preparser::Stack;
use Mediawiki::Preparser::Stack::Element::Part;
use Mediawiki::PhpFunctions;


# use Carp::Always;

sub parse
{

my $text = shift;
my $options = shift || {result=>'xml'};
my $flags;

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

my $enableOnlyinclude = 1; # $enableOnlyinclude = false;
# FIXME we should get it through some kind of options or something


#my $xmlishRegex = implode( '|', array_merge( $xmlishElements, $ignoredTags ) );

#// Use "A" modifier (anchored) instead of "^", because ^ doesn't work with an offset
#my $elementsRegex = "~($xmlishRegex)(?:\s|\/>|>)|(!--)~iA";

my $ignoredTags = [ 'noinclude', '/noinclude', 'onlyinclude', '/onlyinclude' ]; # this list should be somehow confugurable, as it depends on how the atricle is used: is it is icluded in other article or not
my $ignoredElements = [ 'noinclude', 'onlyinclude' ];

my $xmlishRegex = 'pre|nowiki|gallery|rss|includeonly|noinclude|/noinclude|onlyinclude|/onlyinclude';
		#// Use "A" modifier (anchored) instead of "^", because ^ doesn't work with an offset
#my		$elementsRegex = '~($xmlishRegex)(?:\s|\/>|>)|(!--)~iA';
my		$elementsRegex = '~^('.$xmlishRegex.')(?:\s|\/>|>)|(!--)~i';


my $stack = new Mediawiki::Preparser::Stack();
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
my $endPos;
my $inner;
my $wsStart;
my $wsEnd;
my $startPos;
my $lowerName;
my $attrStart;
my $tagEndPos;
my $noMoreGT;
my $tagStartPos;
my $attrEnd;
my $close;
#
my $count;
my $piece;
my $part;
my $wsLength;
my $searchStart;
my $equalsLength;
my $element;
my $element_obj; #this var is perl implementation only;
my $maxCount;
my $matchingCount;
my $name;
my $parts;
my $title;
my $title_obj; #perl only
my $attr;
my $argIndex;
my $argName;
my $argValue;
my $names;
my $skippedBraces;
my $enclosingAccum;
while ()
{
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
					$stack->appendObjAccum(htmlspecialchars( substr( $text, $i, $literalLength ) )); # perl implementation only
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
			if ( $found eq 'angle' ) {
				$matches = []; #false;
				# // Handle </onlyinclude>
				if ( $enableOnlyinclude && substr( $text, $i, strlen( '</onlyinclude>' ) ) eq '</onlyinclude>' ) {
					$findOnlyinclude = 1; # true;
					next; # continue;
				}
				#// Determine element name
				if ( !preg_match( $elementsRegex, $text, $matches, 0, $i + 1 ) ) {
					#// Element name missing or not listed
					$$accum .= '&lt;'; # $accum .= '&lt;';
					$stack->appendObjAccum('&lt;'); # perl implementation only
					++$i;
					next; # continue;
				}
				#// Handle comments
				if ( isset( $matches->[2] ) && $matches->[2] eq '!--' ) {
					#// To avoid leaving blank lines, when a comment is both preceded
					#// and followed by a newline (ignoring spaces), trim leading and
					#// trailing spaces and one of the newlines.
					#// Find the end
					$endPos = strpos( $text, '-->', $i + 4 );
					if ( ! defined $endPos ) {  # $endPos === false
						#// Unclosed comment in input, runs to end
						$inner = substr( $text, $i );
						$$accum .= '<comment>' . htmlspecialchars( $inner ) . '</comment>';
						$stack->appendObjAccum(_prepare_obj_comment(htmlspecialchars( $inner ), $i, 'unclosed'));  # perl specific
						$i = $lengthText;
					} else {
						#// Search backwards for leading whitespace
						$wsStart = $i ? ( $i - strspn( $revText, ' ', $lengthText - $i ) ) : 0;
						#// Search forwards for trailing whitespace
						#// $wsEnd will be the position of the last space (or the '>' if there's none)
						$wsEnd = $endPos + 2 + strspn( $text, ' ', $endPos + 3 );
						#// Eat the line if possible
						#// TODO: This could theoretically be done if $wsStart == 0, i.e. for comments at
						#// the overall start. That's not how Sanitizer::removeHTMLcomments() did it, but
						#// it's a possible beneficial b/c break.
						if ( $wsStart > 0 && substr( $text, $wsStart - 1, 1 ) eq "\n"
							&& substr( $text, $wsEnd + 1, 1 ) eq "\n" )
						{
							$startPos = $wsStart;
							$endPos = $wsEnd + 1;
							#// Remove leading whitespace from the end of the accumulator
							#// Sanity check first though
							$wsLength = $i - $wsStart;
							if ( $wsLength > 0 && substr( $$accum, -$wsLength ) eq str_repeat( ' ', $wsLength ) ) { # === -> eq
# According to the issue #2
# https://github.com/dhyannataraj/perl-mediawiki-parser/issues/2
# We will not add leading and trailing spaces for full line span comments inside comments object
# So we will not clean spaces from obj accum as it is done for common $$accum
# and _prepare_obj_comment() will actualy ignore leading spaces as it is still in the accum,
# and add trailing spaces and \n to the accum after the comment as it should be
								$$accum = substr( $$accum, 0, -$wsLength );
							}
							#// Do a line-start run next time to look for headings after the comment
							$fakeLineStart = 1; # true -> 1
						} else {
							#// No line to eat, just take the comment itself
							$startPos = $i;
							$endPos += 2;
						}
						if ( $stack->top ) {
							$part = $stack->top->getCurrentPart();
							if ( ! (isset( $part->commentEnd ) && $part->commentEnd == $wsStart - 1 )) {
								$part->{visualEnd} = $wsStart;
							}
							# // Else comments abutting, no change in visual end
							$part->{commentEnd} = $endPos;
						}
						$i = $endPos + 1;
						$inner = substr( $text, $startPos, $endPos - $startPos + 1 );
						$$accum .= '<comment>' . htmlspecialchars( $inner ) . '</comment>';
						$stack->appendObjAccum(_prepare_obj_comment(htmlspecialchars( $inner ), $startPos));
					}
					next; # continue; --> next;
				}
				$name = $matches->[1];  #   $matches[1] --> $matches->[1]
				$lowerName = strtolower( $name );
				$attrStart = $i + strlen( $name ) + 1;
				#// Find end of tag
				$tagEndPos = $noMoreGT ? undef : strpos( $text, '>', $attrStart );
				if ( ! defined $tagEndPos  ) {  # $tagEndPos === false --> ! defined $tagEndPos
					#// Infinite backtrack
					#// Disable tag search to prevent worst-case O(N^2) performance
					$noMoreGT = 1; # true --> 1
					$$accum .= '&lt;';
# FIXME тут ревлизлвать объектную часть
					++$i;
					next; # continue; --> next;
				}
				#// Handle ignored tags
				if ( in_array( $lowerName, $ignoredTags ) ) {
					$$accum .= '<ignore>' . htmlspecialchars( substr( $text, $i, $tagEndPos - $i + 1 ) ) . '</ignore>';
#FIXME тут реализовать объектную часть
					$i = $tagEndPos + 1;
					next; # continue; --> next;
				}
				$tagStartPos = $i;
				if ( substr($text,$tagEndPos-1,1) eq '/' ) { # $text[$tagEndPos-1] --> substr($text,$tagEndPos-1,1) 
					$attrEnd = $tagEndPos - 1;
					$inner = undef;  # null --> undef
					$i = $tagEndPos + 1;
					$close = '';
				} else {
					$attrEnd = $tagEndPos;
					#// Find closing tag
					if ( preg_match( '/<\/' . preg_quote( $name, '/' ) . '\s*>/i',               #  all " --> '
							$text, $matches, 'PREG_OFFSET_CAPTURE', $tagEndPos + 1 ) )   #  PREG_OFFSET_CAPTURE --> 'PREG_OFFSET_CAPTURE'
					{
						$inner = substr( $text, $tagEndPos + 1, $matches->[0][1] - $tagEndPos - 1 );  # $matches[ --> $matches->[
						$i = $matches->[0][1] + strlen( $matches->[0][0] );                           # $matches[ --> $matches->[
						$close = '<close>' . htmlspecialchars( $matches->[0][0] ) . '</close>';       # $matches[ --> $matches->[
					} else {
						# // No end tag -- let it run out to the end of the text.
						$inner = substr( $text, $tagEndPos + 1 );
						$i = $lengthText;
						$close = '';
					}
				}
				# // <includeonly> and <noinclude> just become <ignore> tags
				if ( in_array( $lowerName, $ignoredElements ) ) {
					$$accum .= '<ignore>' . htmlspecialchars( substr( $text, $tagStartPos, $i - $tagStartPos ) )
						. '</ignore>';
#FIXME add obj oriented implementation here
# FIXME check how should it really work
					next;  # continue; --> next;
				}
				$$accum .= '<ext>';
				if ( $attrEnd <= $attrStart ) {
					$attr = '';
				} else {
					$attr = substr( $text, $attrStart, $attrEnd - $attrStart );
				}
				$$accum .= '<name>' . htmlspecialchars( $name ) . '</name>' .
					#// Note that the attr element contains the whitespace between name and attribute,
					#// this is necessary for precise reconstruction during pre-save transform.
					'<attr>' . htmlspecialchars( $attr ) . '</attr>';
				if ( defined $inner ) {   # $inner !== null --> defined $inner
					$$accum .= '<inner>' . htmlspecialchars( $inner ) . '</inner>';
				}
				$$accum .= $close . '</ext>';
#FIXME add obj oriented implementation here





			} elsif ( $found eq 'line-start' ) {
				#// Is this the start of a heading?
				#// Line break belongs before the heading element in any case
				if ( $fakeLineStart ) {
					$fakeLineStart = 0;  # $fakeLineStart = false;
				} else {
					$$accum .= $curChar;
					$stack->appendObjAccum($curChar); # perl implementation only
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
						'parts' => [ new Mediawiki::Preparser::Stack::Element::Part('=' x $count)  ], # array( new PPDPart( str_repeat( '=', $count ) ) ),
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
						$element_obj = _prepare_piece($piece,$count,$headingIndex); # perl implementation only
						$headingIndex++;
					} else {
						#// Single equals sign on its own line, count=0
						$element = $$accum;
						$element_obj = $$accum; # perl implementation only
					}
				} else {
					#// No match, no <h>, just pass down the inner text
					$element = $$accum;
					$element_obj = $part->{obj_accum}; # perl implementation only
				}
				#// Unwind the stack
				$stack->pop();
				$accum = $stack->getAccum();
				$flags = $stack->getFlags();
				$findEquals = $flags->{findEquals}; # extract( $flags );
				$findPipe = $flags->{findPipe}; # extract( $flags );
				$inHeading = $flags->{inHeading}; # extract( $flags );
				
				#// Append the result to the enclosing accumulator
				$$accum .= $element;
				$stack->appendObjAccum($element_obj); # perl implementation only
				#// Note that we do NOT increment the input pointer.
				#// This is because the closing linebreak could be the opening linebreak of
				#// another heading. Infinite loops are avoided because the next iteration MUST
				#// hit the heading open case above, which unconditionally increments the
				#// input pointer.
			} elsif ( $found eq 'open' ) {
				# count opening brace characters
				$count = strspn( $text, $curChar, $i );
				# we need to add to stack only if opening brace count is enough for one of the rules
				if ( $count >= $rule->{'min'} ) {   #if ( $count >= $rule['min'] ) {
					# Add it to the stack

					$piece = { #array(
						'open' => $curChar,
						'close' => $rule->{'end'},
						'count' => $count,
						'lineStart' => ($i > 0 && substr($text,$i-1,1) eq "\n"),    #($i > 0 && $text[$i-1] == "\n"),
					}; # );
					$stack->push( $piece );
					$accum = $stack->getAccum();
					$flags = $stack->getFlags();
					$findEquals = $flags->{findEquals}; # extract( $flags );
					$findPipe = $flags->{findPipe}; # extract( $flags );
					$inHeading = $flags->{inHeading}; # extract( $flags );
				} else {
					# Add literal brace(s)
					$$accum .= htmlspecialchars( str_repeat( $curChar, $count ) );
					$stack->appendObjAccum(htmlspecialchars( str_repeat( $curChar, $count ) )); # perl specific
				}
				$i += $count;
			} elsif ( $found eq 'close' ) {
				$piece = $stack->top;
				# lets check if there are enough characters for closing brace
				$maxCount = $piece->count;
				
				$count = strspn( $text, $curChar, $i, $maxCount );
				# check for maximum matching characters (if there are 5 closing
				# characters, we will probably need only 3 - depending on the rules)
				$rule = $rules->{$piece->open};   #$rules[$piece->open];
				if ( $count > $rule->{'max'} ) {   # rule['max'] ) {
					# The specified maximum exists in the callback array, unless the caller
					# has made an error
					$matchingCount = $rule->{'max'};  # $rule['max'];
				} else {
					# Count is less than the maximum
					# Skip any gaps in the callback array to find the true largest match
					# Need to use array_key_exists not isset because the callback can be null
					$matchingCount = $count;
					while ( $matchingCount > 0 && !array_key_exists( $matchingCount, $rule->{'names'} ) ) {  # $rule['names']
						--$matchingCount;
					}
				}
				if ( $matchingCount <= 0 ) {
					# No matching element found in callback array
					# Output a literal closing brace and continue
					$$accum .= htmlspecialchars( str_repeat( $curChar, $count ) );
					$stack->appendObjAccum(htmlspecialchars( str_repeat( $curChar, $count ) )); #perl only
					$i += $count;
					next; #continue;
				}
				$name = $rule->{'names'}->{$matchingCount};   # $rule['names'][$matchingCount];
				if ( ! defined $name ) {   # if ( $name === null ) {
					#// No element, just literal text
die "please reoprt the case when you get this!";
					$element = $piece->breakSyntax( $matchingCount ) . str_repeat( $rule->{'end'}, $matchingCount );
					$element_obj = $element;
				} else {
					# Create XML element
					# Note: $parts is already XML, does not need to be encoded further
					$parts = $piece->parts;
					$title = ${$parts->[0]->out};  # $parts[0]->out;
					$title_obj = $parts->[0];
					shift @{$parts}; # $parts->[0] = undef; # unset( $parts[0] );
					
					# The invocation is at the start of the line if lineStart is set in
					# the stack, and all opening brackets are used up.
					if ( $maxCount == $matchingCount && !empty( $piece->lineStart ) ) {
						$attr = ' lineStart="1"';
					} else {
						$attr = '';
					}
					$element = "<$name$attr>";
					$element .= "<title>$title</title>";
					$argIndex = 1;
					foreach my $part ( @$parts ) {   # foreach ( $parts as $part ) {   
						if ( isset( $part->eqpos ) ) {
							$argName = substr( ${$part->out}, 0, $part->eqpos );
							$argValue = substr( ${$part->out}, $part->eqpos + 1 );
							$element .= "<part><name>$argName</name>=<value>$argValue</value></part>";
						} else {
							$element .= "<part><name index=\"$argIndex\" /><value>".${$part->out}."</value></part>";
							$argIndex++;
						}
					}
					$element .= "</$name>";
					$element_obj =  _prepare_piece($piece,$title_obj,$matchingCount);
				}
				# Advance input pointer
				$i += $matchingCount;
				# Unwind the stack
				$stack->pop();
				$accum = $stack->getAccum();
				# Re-add the old stack element if it still has unmatched opening characters remaining
				if ( $matchingCount < $piece->count ) {
					$piece->{parts} = [ new Mediawiki::Preparser::Stack::Element::Part()  ]; # array( new PPDPart );
					$piece->{count} -= $matchingCount;
					# do we still qualify for any callback with remaining count?
					$names = $rules->{$piece->open}->{'names'};
					$skippedBraces = 0;
					$enclosingAccum = $accum;
					while ( $piece->count ) {
						if ( array_key_exists( $piece->count, $names ) ) {
							$stack->push( $piece );
							$accum = $stack->getAccum();
							last; # break;
						}
						--$piece->{count};
						$skippedBraces ++;
					}
					$$enclosingAccum .= str_repeat( $piece->open, $skippedBraces );
					$element_obj = [str_repeat( $piece->open, $skippedBraces ), $element_obj] if $skippedBraces > 0;
				}
				$flags = $stack->getFlags();
				$findEquals = $flags->{findEquals}; # extract( $flags );
				$findPipe = $flags->{findPipe}; # extract( $flags );
				$inHeading = $flags->{inHeading}; # extract( $flags );
				# Add XML element to the enclosing accumulator
				$$accum .= $element;
				$stack->appendObjAccum($element_obj); # perl implementation\ only
			} elsif ( $found eq 'pipe' ) {
				$findEquals = 1; #true; # // shortcut for getFlags()
				$stack->addPart();
				$accum = $stack->getAccum();
				++$i;
			} elsif ( $found eq 'equals' ) {
				$findEquals = 0; # false; # // shortcut for getFlags() # FIXME do not understand here
				$stack->getCurrentPart()->{eqpos} = strlen( $$accum );  # $stack->getCurrentPart()->eqpos = strlen( $accum ); 
				$$accum .= '=';
				$stack->appendObjAccum('=',{special_equal=>1}); #perl only
				++$i;
			}
		}
		# Output any remaining unclosed brackets
		foreach  my $piece (@{$stack->stack} ) {
			$stack->{rootAccum} .= $piece->breakSyntax();
		}
		$stack->breakSyntaxObj();
		$stack->{rootAccum} .= '</root>';
#		$xml = $stack->rootAccum;

return $stack->{rootObjAccum} if $options->{result} eq 'obj';
return $stack->{rootAccum} if $options->{result} eq 'xml';
die "Unknown result option: ".$options->{result};
}


# this function is about prepearing an element piece for oject-oriented accum
# this functionality exists in perl implementation only; in php implementation there is 
# plaintext accum only
sub _prepare_piece
{
  my $piece = dclone shift;
  my @args = @_;
  if ( ($piece->{open} eq "\n") && ($piece->{close} eq "\n") ) # this is a section heading element
  {
    $piece->{open} = "=";
    $piece->{close} = "=";
    $piece->{count} = shift @args;
    $piece->{header_index} = shift @args;
    
    my $pattern = "^".'=' x $piece->{count};
    $piece->{parts}->[0]->{obj_accum}->[0] =~ s/$pattern//;
    shift @{$piece->{parts}->[0]->{obj_accum}} if $piece->{parts}->[0]->{obj_accum}->[0] eq '';

    # here we shuld remove some trailing equal signs. Teoretically. But practically 
    # due to issue #1 https://github.com/dhyannataraj/perl-mediawiki-parser/issues/1
    # we skip all comments and spaces and then remove needed ammount of equal signs
    my $i = -1;
    while (
             ( (ref ($piece->{parts}->[0]->{obj_accum}->[$i]) ne '') && ($piece->{parts}->[0]->{obj_accum}->[$i]->{open} eq "<!--") ) ||
             ( (ref ($piece->{parts}->[0]->{obj_accum}->[$i]) eq '') && ($piece->{parts}->[0]->{obj_accum}->[$i] =~ /^\s+$/) )
          )
    {
      $i--;
      last if (-$i >= int @{$piece->{parts}->[0]->{obj_accum}}); # do not miss the end of array :-)
    }

    $pattern = '=' x $piece->{count} .'(\s*)$';  # (\s*) also added here due to issue #1
    $piece->{parts}->[0]->{obj_accum}->[$i] =~ s/$pattern/$1/;
    pop @{$piece->{parts}->[0]->{obj_accum}} if $piece->{parts}->[0]->{obj_accum}->[$i] eq '';
  } else
  {
    my $title = shift @args;
    my $real_count = shift @args;
    unshift @{$piece->{parts}}, $title if defined $title;
    $piece->{count} = $real_count if defined $real_count;
  }
  foreach my $part (@{$piece->{parts}})
  {
    delete $part->{out} ;
    delete $part->{eqpos};
    
    delete $part->{visualEnd}; # do not think somebody will need these two, but it will make writing autotest simpler
    delete $part->{commentEnd};
  }
  return $piece;
}

sub _prepare_obj_comment
{
  my $content = shift;
  my $pos = shift;
  my $unclosed = shift;
  my $trailing_spaces = undef;
  
  $content =~ s/^(\s*)\&lt;\!--//;        #\s added here due to issue #2 
  my $leading_spaces = $1;                # fix comment start position as it is given including leading spaces
  $pos += length ($leading_spaces) if defined $leading_spaces;
  
  if (!$unclosed)
  {
    $content =~ s/--\&gt;(\s*)$//;
    if ($1)
    {
      # spaces might come into somment text only in case described in issue #2 
      # https://github.com/dhyannataraj/perl-mediawiki-parser/issues/2
      # leading spaces is not removed from obj-accum, so we will just clear them
      # trailing spaces are ommited, so we would have to add them back to the obj accum
      $trailing_spaces  = $1;
    }
  }
  my $res = {open => '<!--',
             close => '-->',
             'startPos' => $pos,
              'parts' => [
                          bless( {
                                    'obj_accum' => [
                                                     $content
                                                   ]
                                 }, 'Mediawiki::Preparser::Stack::Element::Part' )
                          ],

             };
  $res->{unclosed} = 1 if $unclosed;
  $res = bless ($res, 'Mediawiki::Preparser::Stack::Element');
  
  return $res unless $trailing_spaces;
  return [$res, $trailing_spaces];
}

1;