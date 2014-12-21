package Solaris::Perf::Web::Controller::Flamegraph;
use Moose;
use DateTime   qw();
use IO::Scalar qw();
use File::Temp qw();
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

# VERSION

=head1 NAME

Solaris::Perf::Web::Controller::Flamegraph - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

#
# Tunables
#
our $encoding;
our $fonttype = "Verdana";
our $imagewidth = 1200;               # max width, pixels
our $frameheight = 16;                # max height is dynamic
our $fontsize = 12;                   # base text size
our $fontwidth = 0.59;                # avg width relative to fontsize
our $minwidth = 0.1;                  # min function width, pixels
our $nametype = "Function:";          # what are the names in the data?
our $countname = "samples";           # what are the counts in the data?
our $colors = "hot";                  # color theme
our $bgcolor1 = "#eeeeee";            # background color gradient start
our $bgcolor2 = "#eeeeb0";            # background color gradient stop
our $nameattrfile;                    # file holding function attributes
our $timemax;                         # (override the) sum of the counts
our $factor = 1;                      # factor to scale counts by
our $hash = 0;                        # color by function name
our $palette = 0;                     # if we use consistent palettes (default off)
our %palette_map;                     # palette map hash
our $pal_file = "palette.map";        # palette map file name
our $stackreverse = 0;                # reverse stack order, switching merge end
our $inverted = 0;                    # icicle graph
our $negate = 0;                      # switch differential hues
our $titletext = "";                  # centered heading
our $titledefault = "Flame Graph";    # overwritten by --title
our $titleinverted = "Icicle Graph";	#   "    "

#
# Package Lexical Internal Variables (to be eliminated)
#
# internals
my $ypad1 = $fontsize * 4;      # pad top, include title
my $ypad2 = $fontsize * 2 + 10; # pad bottom, include labels
my $xpad = 10;                  # pad lefm and right
my $framepad = 1;               # vertical padding for frames
my %Events;
my %nameattr;

#
# Various Package Globals (to be eliminated)
#
my %Node;
my %Tmp;
#
# Parse Input Variables (to be eliminated)
#



#
# PRIVATE SVG PACKAGE (to be moved into it's own modules under
# Solaris::Perf::Flamegraph, ultimately
#
# SVG functions
{ package SVG;
  sub new {
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self;
  }

  sub header {
    my ($self, $w, $h) = @_;
    my $enc_attr = '';
    if (defined $encoding) {
      $enc_attr = qq{ encoding="$encoding"};
    }
    $self->{svg} .= <<SVG;
<?xml version="1.0"$enc_attr standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" width="$w" height="$h" onload="init(evt)" viewBox="0 0 $w $h" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
SVG
  }

  sub include {
    my ($self, $content) = @_;
    $self->{svg} .= $content;
  }

  sub colorAllocate {
    my ($self, $r, $g, $b) = @_;
    return "rgb($r,$g,$b)";
  }

  sub group_start {
    my ($self, $attr) = @_;

    my @g_attr = map {
      exists $attr->{$_} ? sprintf(qq/$_="%s"/, $attr->{$_}) : ()
    } qw(class style onmouseover onmouseout onclick);

    push @g_attr, $attr->{g_extra} if $attr->{g_extra};
    $self->{svg} .= sprintf qq/<g %s>\n/, join(' ', @g_attr);

    $self->{svg} .= sprintf qq/<title>%s<\/title>/, $attr->{title}
    if $attr->{title}; # should be first element within g container

    if ($attr->{href}) {
      my @a_attr;
      push @a_attr, sprintf qq/xlink:href="%s"/, $attr->{href} if $attr->{href};
      # default target=_top else links will open within SVG <object>
      push @a_attr, sprintf qq/target="%s"/, $attr->{target} || "_top";
      push @a_attr, $attr->{a_extra}   if $attr->{a_extra};
      $self->{svg} .= sprintf qq/<a %s>/, join(' ', @a_attr);
    }
  }

  sub group_end {
    my ($self, $attr) = @_;
    $self->{svg} .= qq/<\/a>\n/ if $attr->{href};
    $self->{svg} .= qq/<\/g>\n/;
  }

  sub filledRectangle {
    my ($self, $x1, $y1, $x2, $y2, $fill, $extra) = @_;
    $x1 = sprintf "%0.1f", $x1;
    $x2 = sprintf "%0.1f", $x2;
    my $w = sprintf "%0.1f", $x2 - $x1;
    my $h = sprintf "%0.1f", $y2 - $y1;
    $extra = defined $extra ? $extra : "";
    $self->{svg} .= qq/<rect x="$x1" y="$y1" width="$w" height="$h" fill="$fill" $extra \/>\n/;
  }

  sub stringTTF {
    my ($self, $color, $font, $size, $angle, $x, $y, $str, $loc, $extra) = @_;
    $x = sprintf "%0.2f", $x;
    $loc = defined $loc ? $loc : "left";
    $extra = defined $extra ? $extra : "";
    $self->{svg} .= qq/<text text-anchor="$loc" x="$x" y="$y" font-size="$size" font-family="$font" fill="$color" $extra >$str<\/text>\n/;
  }

  sub svg {
    my $self = shift;
    return "$self->{svg}</svg>\n";
  }
  1;
}


=head1 METHODS

=cut

=head2 list

=cut

sub list :Local {
  my ($self, $c) = @_;

  #my $dtf = $c->model("DB::Flamegraph")->storage->datetime_parser;

  $c->stash(flamegraphs =>
    [
     $c->model("DB::Flamegraph")->search({},{ join     => 'host',
                                              prefetch => 'host',
                                            }
     )->all
    ] );

  $c->stash(template => 'flamegraph/list.tt');
}

=head2 base

Get the flamegraph result set ready for subsequent work

=cut

sub base :Chained('/') :PathPart('flamegraph') :CaptureArgs(0) {
  my ($self, $c) = @_;

  # Store the ResultSet in stash so it's available for other methods
  # This works because of our mapping in the config of
  # Solaris::Perf::Web::Schema.pm
  $c->stash(flamegraph_rs => $c->model('DB::Flamegraph'),
            host_rs       => $c->model('DB::Host'),
           );

  # Print a message to the debug log
  $c->log->debug('*** INSIDE FLAMEGRAPH BASE METHOD ***');
}

=head2 object

Fetch the specified flamegraph object based on the flamegraph ID and store
it in the stash

=cut

sub object :Chained('base') :PathPart('id') :CaptureArgs(1) {
  # $id = primary key of flamegraph to delete
  my ($self, $c, $id) = @_;

  # Find the flamegraph object and store it in the stash
  $c->stash(object => $c->stash->{flamegraph_rs}->find($id));

  # Make sure the lookup was successful.  You would probably want to do
  # something like this to be more robust:
  # $c->detach('/error_404') if !$c->stash->{object};
  die "Flamegraph $id not found!" if !$c->stash->{object};

  # Print a message to the debug log
  $c->log->debug("*** INSIDE OBJECT METHOD for obj id=$id ***");
}

=head delete

Delete a flamegraph

=cut

sub delete :Chained('object') :PathPart('delete') :Args(0) {
  my ($self, $c) = @_;

  # use the flamegraph object staved by 'object' and delete it
  $c->stash->{object}->delete;

  # Set a status message to be displayed at the top of the view
  # NOTE: Can only work across flash or some other session type
  # $c->stash->{status_msg} = "Flamegraph deleted";

  # Redirect the user back to the list page.  Note the use of
  # $self->action_for as earlier.
  # For the moment, including status message as a request query param.
  # Fix later.
  $c->response->redirect($c->uri_for($self->action_for('list'),
    { status_msg => "Flamegraph deleted." } ));
}

=head2 upload_stack

Upload stack trace output via a command line utility (usually)

=cut

sub upload_stack :Chained('base') :PathPart('upload_stack') :Args(4) {
  my ($self, $c, $hostname, $begin_epoch_utc, $end_epoch_utc, $tz ) = @_;

#$DB::single = 1;


  # Print a message to the debug log
  $c->log->debug('*** INSIDE FLAMEGRAPH UPLOAD_STACK METHOD ***');
  $c->log->debug("Hostname: $hostname");
  $c->log->debug("TimeZone: $tz");
  # We're getting data in UTC, and we must store it in that format.
  # Do NOT store data in any other time zone!
  my $begin_dt_utc = DateTime->from_epoch( epoch => $begin_epoch_utc,
                                           time_zone => 'UTC' );
  $c->log->debug("Begin Sample (UTC): $begin_dt_utc");
  my $begin_dt_lcl = $begin_dt_utc->clone->set_time_zone( $tz );
  $c->log->debug("Begin Sample ($tz): $begin_dt_lcl");

  my $end_dt_utc  = DateTime->from_epoch( epoch => $end_epoch_utc,
                                          time_zone => 'UTC' );
  $c->log->debug("End Sample (UTC): $end_dt_utc");
  my $end_dt_lcl = $end_dt_utc->clone->set_time_zone( $tz );
  $c->log->debug("End Sample ($tz): $end_dt_lcl");

  $c->stash(begin_dt_utc => $begin_dt_utc,
            begin_dt_lcl => $begin_dt_lcl,
            end_dt_utc   => $end_dt_utc,
            end_dt_lcl   => $end_dt_lcl,
            hostname     => $hostname,
            tz           => $tz, );

  $c->forward('stack_collapse');
  $c->forward('create_svg');

  # The flamegraph that was added (if any)
  my $f_id = $c->stash->{flamegraph_id};

  #print Data::Dumper($c->request->parameters);
  $c->res->content_type('text/html');
  $c->res->body($c->uri_for("/flamegraph/svg/$f_id"));
}

=head2 stack_collapse

Collapse stacks for use in generating flame graphs

=cut

sub stack_collapse :Private {
  my ($self, $c) = @_;
  my (%collapsed,$collapsed);
  my $headerlines = 3;

  $c->log->debug('*** INSIDE FLAMEGRAPH STACK_COLLAPSE METHOD ***');

  my $nr = 0;
  my @stack;

  my $description   = $c->req->param('description');
  $c->log->debug("*** DESCRIPTION: [$description] ***");
  $c->stash('description' => $description);

  my $upload        = $c->req->upload('upload');

  my $fhu           = $upload->fh;

  foreach (<$fhu>) {
    next if $nr++ < $headerlines;
    chomp;

    if (m/^\s*(\d+)+$/) {
      $collapsed{join(";", @stack)} = $1;
      @stack = ();
      next;
    }

    next if (m/^\s*$/);

    my $frame = $_;
    $frame =~ s/^\s*//;
    $frame =~ s/\+[^+]*$//;
    # Remove arguments from C++ function names.
    $frame =~ s/(..)[(<].*/$1/;
    $frame = "-" if $frame eq "";
    unshift @stack, $frame;
  }

  foreach my $k (sort { $a cmp $b } keys %collapsed) {
    $collapsed .= sprintf("$k $collapsed{$k}\n");
  } 

  my $host_rs       = $c->stash->{host_rs};
  my $flamegraph_rs = $c->stash->{flamegraph_rs};
  my $begin_dt_utc  = $c->stash->{begin_dt_utc};
  my $end_dt_utc    = $c->stash->{end_dt_utc};
  my $hostname      = $c->stash->{hostname};
  my $tz            = $c->stash->{tz};

  my $host = $host_rs->find_or_create({ name     => $hostname,
                                        timezone => $tz, });
 

  my $flamegraph =
    $flamegraph_rs->create({ host_fk  => $host->host_id,
                             creation => DateTime->now(time_zone => 'UTC'),
                             begin    => $begin_dt_utc,
                             end      => $end_dt_utc,
                             stacks   => $collapsed,
                           });

  # for use by create_svg later
  $c->stash('flamegraph' => $flamegraph);
}

=head2 svg

=cut

sub svg :Chained('/') :PathPart('flamegraph/svg') :Args(1) {
  my ($self, $c, $flamegraph_id) = @_;

$DB::single = 1;

  my $rs = $c->model('DB::Flamegraph');
  # NOTE: Don't forget we have to use flamegraph_id instead of flamegraph_id,
  #       due to the interpretation of Camel Casing by Catalyst
  my $svg = $rs->search({ flamegraph_id => $flamegraph_id })->single->svg;

  #$c->res->content_type('text/html');
  $c->res->body($svg);
}


=head2 create_svg

=cut

sub create_svg :Private {
  my ($self, $c) = @_;

  $c->log->debug('*** INSIDE FLAMEGRAPH SVG_CREATE METHOD ***');
  my $begin_dt_lcl = $c->stash->{begin_dt_lcl};
  my $end_dt_lcl   = $c->stash->{end_dt_lcl};

  my $begin_ymd = $begin_dt_lcl->ymd('/');
  my $end_ymd   = $end_dt_lcl->ymd('/');

  my $start_range = $begin_dt_lcl->ymd('/')  . " " . $begin_dt_lcl->hms(':');
  my $end_range;

  if ( $begin_ymd eq $end_ymd ) {
    $end_range   = $end_dt_lcl->hms(':');
  } else {
    $end_range   = $end_dt_lcl->ymd('/')  . " " . $end_dt_lcl->hms(':');
  }

  my $default_header = $c->stash->{hostname} .
                       " [" . $start_range . " => " .
                              $end_range   . "]";
  $c->log->debug("*** DEFAULT SVG HEADER: [$default_header] ***");

  #my $description = (exists($c->stash->{description}) and defined($c->stash->{description})) ?
  #                  $c->stash->{description} : undef;
  #$c->log->debug("*** SVG HEADER DESCRIPTION: [$description] ***");

  $titletext = $default_header;

  # Global Resets
  %Node = ();
  %Tmp  = ();

  # These were tunables - may yet be again...
  my $timemax;                         # (override the) sum of the counts

  #
  # Parse Input Variables
  #
  my $line;
  my @Data;
  my $time = 0;
  my $last = [];
  my $delta = undef;
  my $ignored = 0;
  my $maxdelta = 1;

  #
  # Package Lexical Internal Variables
  #
  my $depthmax = 0;


  if ($titletext eq "") {
    unless ($inverted) {
      $titletext = $titledefault;
    } else {
      $titletext = $titleinverted;
    }
  }

  #
  # TODO: This can likely be dispensed with - we won't be using it
  #
  if ($nameattrfile) {
    # The name-attribute file format is a function name followed by a tab then
    # a sequence of tab separated name=value pairs.
    open my $attrfh, $nameattrfile or die "Can't read $nameattrfile: $!\n";
    while (<$attrfh>) {
      chomp;
      my ($funcname, $attrstr) = split /\t/, $_, 2;
      die "Invalid format in $nameattrfile" unless defined $attrstr;
      $nameattr{$funcname} = { map { split /=/, $_, 2 } split /\t/, $attrstr };
    }
  }

  if ($colors eq "mem") { $bgcolor1 = "#eeeeee"; $bgcolor2 = "#e0e0ff"; }
  if ($colors eq "io")  { $bgcolor1 = "#f8f8f8"; $bgcolor2 = "#e8e8e8"; }

  # TODO: Extract the collapsed stack into a scalar and treat that scalar
  #       as a filehandle
  my $flamegraph       = $c->stash->{flamegraph};
  my $collapsed_stacks = $flamegraph->stacks;
  my $stack_fh         = IO::Scalar->new(\$collapsed_stacks);

$DB::single = 1;

  # reverse if needed
  foreach (<$stack_fh>) {
    chomp;
    $line = $_;
    if ($stackreverse) {
      # there may be an extra samples column for differentials
      # XXX todo: redo these REs as one. It's repeated below.
      my ($stack, $samples) = (/^(.*)\s+?(\d+(?:\.\d*)?)$/);
      my $samples2 = undef;
      if ($stack =~ /^(.*)\s+?(\d+(?:\.\d*)?)$/) {
        $samples2 = $samples;
        ($stack, $samples) = $stack =~ (/^(.*)\s+?(\d+(?:\.\d*)?)$/);
        unshift @Data, join(";", reverse split(";", $stack)) . " $samples $samples2";
      } else {
        unshift @Data, join(";", reverse split(";", $stack)) . " $samples";
      }
    } else {
      unshift @Data, $line;
    }
  }

  # process and merge frames
  foreach (sort @Data) {
    chomp;
    # there may be an extra samples column for differentials
    my ($stack, $samples) = (/^(.*)\s+?(\d+(?:\.\d*)?)$/);
    my $samples2 = undef;
    if ($stack =~ /^(.*)\s+?(\d+(?:\.\d*)?)$/) {
      $samples2 = $samples;
      ($stack, $samples) = $stack =~ (/^(.*)\s+?(\d+(?:\.\d*)?)$/);
    }
    $delta = undef;
    if (defined $samples2) {
      $delta = $samples2 - $samples;
      $maxdelta = abs($delta) if abs($delta) > $maxdelta;
    }
    unless (defined $samples) {
      ++$ignored;
      next;
    }
    $stack =~ tr/<>/()/;
    $last = flow($last, [ '', split ";", $stack ], $time, $delta);
    if (defined $samples2) {
      $time += $samples2;
    } else {
      $time += $samples;
    }
  }

  flow($last, [], $time, $delta);

  warn "Ignored $ignored lines with invalid format\n" if $ignored;
  die "ERROR: No stack counts found\n" unless $time;

  if ($timemax and $timemax < $time) {
    warn "Specified --total $timemax is less than actual total $time, so ignored\n"
    if $timemax/$time > 0.02; # only warn is significant (e.g., not rounding etc)
    undef $timemax;
  }
  $timemax ||= $time;

  my $widthpertime = ($imagewidth - 2 * $xpad) / $timemax;
  my $minwidth_time = $minwidth / $widthpertime;

  # prune blocks that are too narrow and determine max depth
  while (my ($id, $node) = each %Node) {
    my ($func, $depth, $etime) = split ";", $id;
    my $stime = $node->{stime};
    die "missing start for $id" if not defined $stime;

    if (($etime-$stime) < $minwidth_time) {
      delete $Node{$id};
      next;
    }
    $depthmax = $depth if $depth > $depthmax;
  }

  # Draw canvas
  my $imageheight = ($depthmax * $frameheight) + $ypad1 + $ypad2;
  my $im = SVG->new();
  $im->header($imagewidth, $imageheight);

  my $inc = <<INC;
<defs >
	<linearGradient id="background" y1="0" y2="1" x1="0" x2="0" >
		<stop stop-color="$bgcolor1" offset="5%" />
		<stop stop-color="$bgcolor2" offset="95%" />
	</linearGradient>
</defs>
<style type="text/css">
	.func_g:hover { stroke:black; stroke-width:0.5; cursor:pointer; }
</style>
<script type="text/ecmascript">
<![CDATA[
	var details, svg;
	function init(evt) { 
		details = document.getElementById("details").firstChild; 
		svg = document.getElementsByTagName("svg")[0];
	}
	function s(info) { details.nodeValue = "$nametype " + info; }
	function c() { details.nodeValue = ' '; }
	function find_child(parent, name, attr) {
		var children = parent.childNodes;
		for (var i=0; i<children.length;i++) {
			if (children[i].tagName == name)
				return (attr != undefined) ? children[i].attributes[attr].value : children[i];
		}
		return;
	}
	function orig_save(e, attr, val) {
		if (e.attributes["_orig_"+attr] != undefined) return;
		if (e.attributes[attr] == undefined) return;
		if (val == undefined) val = e.attributes[attr].value;
		e.setAttribute("_orig_"+attr, val);
	}
	function orig_load(e, attr) {
		if (e.attributes["_orig_"+attr] == undefined) return;
		e.attributes[attr].value = e.attributes["_orig_"+attr].value;
		e.removeAttribute("_orig_"+attr);
	}
	function update_text(e) {
		var r = find_child(e, "rect");
		var t = find_child(e, "text");
		var w = parseFloat(r.attributes["width"].value) -3;
		var txt = find_child(e, "title").textContent.replace(/\\([^(]*\\)/,"");
		t.attributes["x"].value = parseFloat(r.attributes["x"].value) +3;
		
		// Smaller than this size won't fit anything
		if (w < 2*$fontsize*$fontwidth) {
			t.textContent = "";
			return;
		}
		
		t.textContent = txt;
		// Fit in full text width
		if (/^ *\$/.test(txt) || t.getSubStringLength(0, txt.length) < w)
			return;
		
		for (var x=txt.length-2; x>0; x--) {
			if (t.getSubStringLength(0, x+2) <= w) { 
				t.textContent = txt.substring(0,x) + "..";
				return;
			}
		}
		t.textContent = "";
	}
	function zoom_reset(e) {
		if (e.attributes != undefined) {
			orig_load(e, "x");
			orig_load(e, "width");
		}
		if (e.childNodes == undefined) return;
		for(var i=0, c=e.childNodes; i<c.length; i++) {
			zoom_reset(c[i]);
		}
	}
	function zoom_child(e, x, ratio) {
		if (e.attributes != undefined) {
			if (e.attributes["x"] != undefined) {
				orig_save(e, "x");
				e.attributes["x"].value = (parseFloat(e.attributes["x"].value) - x - $xpad) * ratio + $xpad;
				if(e.tagName == "text") e.attributes["x"].value = find_child(e.parentNode, "rect", "x") + 3;
			}
			if (e.attributes["width"] != undefined) {
				orig_save(e, "width");
				e.attributes["width"].value = parseFloat(e.attributes["width"].value) * ratio;
			}
		}
		
		if (e.childNodes == undefined) return;
		for(var i=0, c=e.childNodes; i<c.length; i++) {
			zoom_child(c[i], x-$xpad, ratio);
		}
	}
	function zoom_parent(e) {
		if (e.attributes) {
			if (e.attributes["x"] != undefined) {
				orig_save(e, "x");
				e.attributes["x"].value = $xpad;
			}
			if (e.attributes["width"] != undefined) {
				orig_save(e, "width");
				e.attributes["width"].value = parseInt(svg.width.baseVal.value) - ($xpad*2);
			}
		}
		if (e.childNodes == undefined) return;
		for(var i=0, c=e.childNodes; i<c.length; i++) {
			zoom_parent(c[i]);
		}
	}
	function zoom(node) { 
		var attr = find_child(node, "rect").attributes;
		var width = parseFloat(attr["width"].value);
		var xmin = parseFloat(attr["x"].value);
		var xmax = parseFloat(xmin + width);
		var ymin = parseFloat(attr["y"].value);
		var ratio = (svg.width.baseVal.value - 2*$xpad) / width;
		
		// XXX: Workaround for JavaScript float issues (fix me)
		var fudge = 0.0001;
		
		var unzoombtn = document.getElementById("unzoom");
		unzoombtn.style["opacity"] = "1.0";
		
		var el = document.getElementsByTagName("g");
		for(var i=0;i<el.length;i++){
			var e = el[i];
			var a = find_child(e, "rect").attributes;
			var ex = parseFloat(a["x"].value);
			var ew = parseFloat(a["width"].value);
			// Is it an ancestor
			if ($inverted == 0) {
				var upstack = parseFloat(a["y"].value) > ymin;
			} else {
				var upstack = parseFloat(a["y"].value) < ymin;
			}
			if (upstack) {
				// Direct ancestor
				if (ex <= xmin && (ex+ew+fudge) >= xmax) {
					e.style["opacity"] = "0.5";
					zoom_parent(e);
					e.onclick = function(e){unzoom(); zoom(this);};
					update_text(e);
				}
				// not in current path
				else
					e.style["display"] = "none";
			}
			// Children maybe
			else {
				// no common path
				if (ex < xmin || ex + fudge >= xmax) {
					e.style["display"] = "none";
				}
				else {
					zoom_child(e, xmin, ratio);
					e.onclick = function(e){zoom(this);};
					update_text(e);
				}
			}
		}
	}
	function unzoom() {
		var unzoombtn = document.getElementById("unzoom");
		unzoombtn.style["opacity"] = "0.0";
		
		var el = document.getElementsByTagName("g");
		for(i=0;i<el.length;i++) {
			el[i].style["display"] = "block";
			el[i].style["opacity"] = "1";
			zoom_reset(el[i]);
			update_text(el[i]);
		}
	}	
]]>
</script>
INC


  $im->include($inc);
  $im->filledRectangle(0, 0, $imagewidth, $imageheight, 'url(#background)');
  my ($white, $black, $vvdgrey, $vdgrey) = (
    $im->colorAllocate(255, 255, 255),
    $im->colorAllocate(0, 0, 0),
    $im->colorAllocate(40, 40, 40),
    $im->colorAllocate(160, 160, 160),
  );
  $im->stringTTF($black, $fonttype, $fontsize + 5, 0.0,
                 int($imagewidth / 2), $fontsize * 2, $titletext, "middle");
  $im->stringTTF($black, $fonttype, $fontsize, 0.0, $xpad,
                 $imageheight - ($ypad2 / 2), " ", "", 'id="details"');
  $im->stringTTF($black, $fonttype, $fontsize, 0.0, $xpad, $fontsize * 2,
                 "Reset Zoom", "",
                 'id="unzoom" onclick="unzoom()" style="opacity:0.0;cursor:pointer"');

  if ($palette) {
    read_palette();
  }

  # Draw frames
  while (my ($id, $node) = each %Node) {
    my ($func, $depth, $etime) = split ";", $id;
    my $stime = $node->{stime};
    my $delta = $node->{delta};

    $etime = $timemax if $func eq "" and $depth == 0;

    my $x1 = $xpad + $stime * $widthpertime;
    my $x2 = $xpad + $etime * $widthpertime;
    my ($y1, $y2);
    unless ($inverted) {
      $y1 = $imageheight - $ypad2 - ($depth + 1) * $frameheight + $framepad;
      $y2 = $imageheight - $ypad2 - $depth * $frameheight;
    } else {
      $y1 = $ypad1 + $depth * $frameheight;
      $y2 = $ypad1 + ($depth + 1) * $frameheight - $framepad;
    }

    my $samples = sprintf "%.0f", ($etime - $stime) * $factor;
    (my $samples_txt = $samples) # add commas per perlfaq5
      =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;

    my $info;
    if ($func eq "" and $depth == 0) {
      $info = "all ($samples_txt $countname, 100%)";
    } else {
      my $pct = sprintf "%.2f", ((100 * $samples) / ($timemax * $factor));
      my $escaped_func = $func;
      $escaped_func =~ s/&/&amp;/g;
      $escaped_func =~ s/</&lt;/g;
      $escaped_func =~ s/>/&gt;/g;
      unless (defined $delta) {
        $info = "$escaped_func ($samples_txt $countname, $pct%)";
      } else {
        my $deltapct = sprintf "%.2f", ((100 * $delta) / ($timemax * $factor));
        $deltapct = $delta > 0 ? "+$deltapct" : $deltapct;
        $info = "$escaped_func ($samples_txt $countname, $pct%; $deltapct%)";
      }
    }

    my $nameattr = { %{ $nameattr{$func} || {} } }; # shallow clone
    $nameattr->{class}       ||= "func_g";
    $nameattr->{onmouseover} ||= "s('".$info."')";
    $nameattr->{onmouseout}  ||= "c()";
    $nameattr->{onclick}     ||= "zoom(this)";
    $nameattr->{title}       ||= $info;
    $im->group_start($nameattr);

    my $color;
    if ($func eq "-") {
      $color = $vdgrey;
    } elsif (defined $delta) {
      $color = color_scale($delta, $maxdelta);
    } elsif ($palette) {
      $color = color_map($colors, $func);
    } else {
      $color = color($colors, $hash, $func);
    }
    $im->filledRectangle($x1, $y1, $x2, $y2, $color, 'rx="2" ry="2"');

    my $chars = int( ($x2 - $x1) / ($fontsize * $fontwidth));
    my $text = "";
    if ($chars >= 3) { # room for one char plus two dots
      $text = substr $func, 0, $chars;
      substr($text, -2, 2) = ".." if $chars < length $func;
      $text =~ s/&/&amp;/g;
      $text =~ s/</&lt;/g;
      $text =~ s/>/&gt;/g;
    }
    $im->stringTTF($black, $fonttype, $fontsize, 0.0, $x1 + 3, 3 + ($y1 + $y2) / 2, $text, "");

    $im->group_end($nameattr);
  }

  #print $im->svg;
  $flamegraph->update({ svg => $im->svg });

  $c->stash( 'flamegraph_id' => $flamegraph->id );

  if ($palette) {
    write_palette();
  }
}

=head1 PRIVATE METHODS

=head2 namehash

=cut

sub namehash :Private {
  # Generate a vector hash for the name string, weighting early over
  # later characters. We want to pick the same colors for function
  # names across different flame graphs.
  my $name = shift;
  my $vector = 0;
  my $weight = 1;
  my $max = 1;
  my $mod = 10;

  # if module name present, trunc to 1st char
  $name =~ s/.(.*?)`//;

  foreach my $c (split //, $name) {
    my $i = (ord $c) % $mod;
    $vector += ($i / ($mod++ - 1)) * $weight;
    $max += 1 * $weight;
    $weight *= 0.70;
    last if $mod > 12;
  }

  return (1 - $vector / $max);
}

=head2 color

=cut

sub color :Private {
  my ($type, $hash, $name) = @_;
  my ($v1, $v2, $v3);

  if ($hash) {
    $v1 = namehash($name);
    $v2 = $v3 = namehash(scalar reverse $name);
  } else {
    $v1 = rand(1);
    $v2 = rand(1);
    $v3 = rand(1);
  }

  # theme palettes
  if (defined $type and $type eq "hot") {
    my $r = 205 + int(50  * $v3);
    my $g =   0 + int(230 * $v1);
    my $b =   0 + int(55  * $v2);
    return "rgb($r,$g,$b)";
  }
  if (defined $type and $type eq "mem") {
    my $r = 0;
    my $g = 190 + int(50  * $v2);
    my $b =   0 + int(210 * $v1);
    return "rgb($r,$g,$b)";
  }
  if (defined $type and $type eq "io") {
    my $r =  80 + int(60 * $v1);
    my $g = $r;
    my $b = 190 + int(55 * $v2);
    return "rgb($r,$g,$b)";
  }

  # multi palettes
  if (defined $type and $type eq "java") {
    if ($name =~ /::/) {		# C++
      $type = "yellow";
    } elsif ($name =~ m:/:) {	# Java (match "/" in path)
      $type = "green"
    } else {			# system
      $type = "red";
    }
    # fall-through to color palettes
  }

  # color palettes
  if (defined $type and $type eq "red") {
    my $r = 200 + int(55 * $v1);
    my $x = 50 + int(80 * $v1);
    return "rgb($r,$x,$x)";
  }
  if (defined $type and $type eq "green") {
    my $g = 200 + int(55 * $v1);
    my $x = 50 + int(60 * $v1);
    return "rgb($x,$g,$x)";
  }
  if (defined $type and $type eq "blue") {
    my $b = 205 + int(50 * $v1);
    my $x = 80 + int(60 * $v1);
    return "rgb($x,$x,$b)";
  }
  if (defined $type and $type eq "yellow") {
    my $x = 175 + int(55 * $v1);
    my $b = 50 + int(20 * $v1);
    return "rgb($x,$x,$b)";
  }
  if (defined $type and $type eq "purple") {
    my $x = 190 + int(65 * $v1);
    my $g = 80 + int(60 * $v1);
    return "rgb($x,$g,$x)";
  }
  if (defined $type and $type eq "orange") {
    my $r = 190 + int(65 * $v1);
    my $g = 90 + int(65 * $v1);
    return "rgb($r,$g,0)";
  }

  return "rgb(0,0,0)";
}

=head2 color_scale

=cut

sub color_scale :Private {
  my ($value, $max) = @_;
  my ($r, $g, $b) = (255, 255, 255);
  $value = -$value if $negate;
  if ($value > 0) {
    $g = $b = int(210 * ($max - $value) / $max);
  } elsif ($value < 0) {
    $r = $g = int(210 * ($max + $value) / $max);
  }
  return "rgb($r,$g,$b)";
}

=head2 color_map

=cut

sub color_map :Private {
  my ($colors, $func) = @_;
  if (exists $palette_map{$func}) {
    return $palette_map{$func};
  } else {
    $palette_map{$func} = color($colors);
    return $palette_map{$func};
  }
}

=head2 write_palette

=cut

sub write_palette :Private {
  open(FILE, ">$pal_file");
  foreach my $key (sort keys %palette_map) {
    print FILE $key."->".$palette_map{$key}."\n";
  }
  close(FILE);
}

=head2 read_palette

=cut

sub read_palette :Private {
  if (-e $pal_file) {
    open(FILE, $pal_file) or die "can't open file $pal_file: $!";
    while ( my $line = <FILE>) {
      chomp($line);
      (my $key, my $value) = split("->",$line);
      $palette_map{$key}=$value;
    }
    close(FILE)
  }
}

=head2 flow

=cut

sub flow :Private {
  my ($last, $this, $v, $d) = @_;

  my $len_a = @$last - 1;
  my $len_b = @$this - 1;

  my $i = 0;
  my $len_same;
  for (; $i <= $len_a; $i++) {
    last if $i > $len_b;
    last if $last->[$i] ne $this->[$i];
  }
  $len_same = $i;

  for ($i = $len_a; $i >= $len_same; $i--) {
    my $k = "$last->[$i];$i";
    # a unique ID is constructed from "func;depth;etime";
    # func-depth isn't unique, it may be repeated later.
    $Node{"$k;$v"}->{stime} = delete $Tmp{$k}->{stime};
    if (defined $Tmp{$k}->{delta}) {
      $Node{"$k;$v"}->{delta} = delete $Tmp{$k}->{delta};
    }
    delete $Tmp{$k};
  }

  for ($i = $len_same; $i <= $len_b; $i++) {
    my $k = "$this->[$i];$i";
    $Tmp{$k}->{stime} = $v;
    if (defined $d) {
      $Tmp{$k}->{delta} += $i == $len_b ? $d : 0;
    }
  }

  return $this;
}

=encoding utf8

=head1 AUTHOR

Gordon Marler

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


