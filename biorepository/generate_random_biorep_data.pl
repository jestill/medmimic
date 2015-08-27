#!/usr/bin/perl -w

# generate_random_data.pl - Creates pseudodata for bioreposiotry testing
# Author  : Jamie Estill
# Contact : jaestill@med.umich.edu
# Started : 1/12/2015
# Edited  : 1/15/2015
#

#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use Getopt::Long;
# The following needed for printing help
use Pod::Select;               # Print subsections of POD documentation
use Pod::Text;                 # Print POD doc as formatted text file
use IO::Scalar;                # For print_help subfunction
use IO::Pipe;                  # Pipe for STDIN, STDOUT for POD docs
use File::Spec;                # Convert a relative path to an abosolute path
use DateTime;                  # Working to get the date to epoch

#-----------------------------+
# VARIABLE SCOPE              |
#-----------------------------+
my ($VERSION) = 0.1;

my $subjfile;                  # The subject input file (ie will provide the fake MRNs)
my $configfile;                # Configuration file
my $outfile;                   # The output file will be the false out data

my @study_data;                # An 2d array of study data for simulation
my @study_samples;             # A 2d array of study samples
my @subjects;                  # A 2d list of MRNs/subjects for picking from
my @config_data;               # The config data to iterate across


# BOOLEANS
my $quiet = 0;
my $verbose = 0;
my $show_help = 0;
my $show_usage = 0;
my $show_man = 0;
my $show_version = 0;
my $do_test = 0;                  # Run the program in test mode
my $do_study_sim = 0;
my $print_header = 0;             # Print header on output file

# Counters
my $num_rows = 0;
my $max_num_rows = 10000;
my $num_studies = 0;
my $num_samples = 0;


# Components of study
my $study_id;
my $study_name;
my $study_pi;
my $study_start_date;
my $study_end_date;
my $study_num_subjects;
my $study_encounter_wait_min;
my $study_encounter_wait_var;
my $study_clinical_dx;
my $study_clinical_dx_prob;

my $study_start_epoch;
my $study_end_epoch;
my $epoch_day = 86400;
    
#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions(# REQUIRED OPTIONS
		    "s|subjects=s"  => \$subjfile,
		    "c|config=s"    => \$configfile,
                    "o|outfile=s"   => \$outfile,
		    # ADDITIONAL OPTIONS
		    "n|num-rows"    => \$max_num_rows,
		    "q|quiet"       => \$quiet,
		    "verbose"       => \$verbose,
		    "header"        => \$print_header,
		    # ADDITIONAL INFORMATION
		    "usage"         => \$show_usage,
		    "test"          => \$do_test,
		    "version"       => \$show_version,
		    "man"           => \$show_man,
		    "h|help"        => \$show_help,);

#-----------------------------+
# PRINT REQUESTED HELP        |
#-----------------------------+
if ( ($show_usage) ) {
    print_help ("usage", $0 );
    exit 1;
}

if ( ($show_help) || (!$ok) ) {
    print_help ("help",  $0 );
    exit 1;
}

if ($show_man) {
    # User perldoc to generate the man documentation.
    system ("perldoc $0");
    exit($ok ? 0 : 2);
}

if ($show_version) {
    print "\ngenerate_random_data.pl:\n".
	"Version: $VERSION\n\n";
    exit 1;
}

print STDERR "Making Fake Test Data\n" unless $quiet;


# PUSH CONFIG DATA TO ARRAY

open (CONFIG, '<'.$configfile) ||
    die "Can not open input file $configfile\n";

if ($outfile) {
    open (OUTFILE, '>'.$outfile) ||
	die "Can not open outfile for output"
}
else {
    open (OUTFILE, ">&STDOUT") ||
	die "Can not open outfile for output"
}

# Print the HEADER
# This would need to be manually changed for other
# data simulations
if ($print_header) {
    print OUTFILE 
	"S_SUBJECT.U_MRN\t".
	"S_SAMPLEFAMILY.COLLECTIONDT\t".
	"S_PARTICIPANTEVENT.EVENTDT\t".
	"S_SAMPLE.S_SAMPLEID\t".
	"S_SAMPLE.SAMPLETYPEID\t".
	"S_SAMPLEFAMILY.COLLECTMETHODID\t".
	"S_SAMPLEDETAIL.TREATMENT\t".
	"S_CLINICALDIAG.S_CLINICALDIAGID\t".
	"S_CLINICALDIAG.CLINICALDIAGDESC\t".
	"TRACKITEM.S_TISSUEID\t".
	"TRACKITEM.TISSUEDESC\t".
	"S_SAMPLE.SSTUDYID\t".
	"S_STUDY.U_PI\t".
	"\n";
}



# Get the MRNs from the input picklist file if one is provided
# otherwise completely random MRNs will be generated
if ($subjfile) {
    open (SUBJECTS, '<'.$subjfile) ||
	die "Can not open subjects file at".$subjfile;
}

while (<SUBJECTS>) {
    chomp;
    my @subject_parts = split (/\t/);
    push (@subjects, $subject_parts[0]);
}
close SUBJECTS;

my $len_picklist = @subjects;
print STDERR "Subject Picklist Length: ".$len_picklist."\n" unless $quiet;


# Going to generate on the fly while parsing thorugh the
# config file.
while (<CONFIG>) {

    chomp;
    my @config_parts = split (/\t/);
    
    my $num_parts = @config_parts;

    # This was a test for parsing the input
    if ($num_parts ne 10) {
	print STDERR "Unexpected number of columns";
	print STDERR $_."\n";
	exit;
    }
    else {
	# We are adding samples to study
	if ($config_parts[1] =~ "sample") {
	    # Push the samples to the sample array for the study being built
	    $num_samples++;
	    my $i = $num_samples - 1;
	    #push(@{$study_samples[$i]}, $_);
	    push(@{$study_samples[$i]}, @config_parts);
	}
	else {
	    unless ($quiet) {
		print STDERR "\t".$num_samples."\n" if $num_samples > 0;
	    }
	    
	    my $sample_ary_len = @study_samples;
	    print STDERR "\t".$sample_ary_len."\n" unless $quiet;

	    # Do not do sim if just starting the first record
	    my $do_sim = 1;
	    if ($num_studies < 1) {
		$do_sim = 0;
	    }

	    if ($do_sim == 1) {


		# Show what we are simulating
		unless ($quiet) {
		    print STDERR "\t\t".$study_id."\n";
		    print STDERR "\t\t".$study_name."\n";
		    print STDERR "\t\t".$study_pi."\n";
		    print STDERR "\t\t".$study_start_date."\n";
		    print STDERR "\t\t".$study_end_date."\n";
		    print STDERR "\t\t".$study_num_subjects."\n";
		    print STDERR "\t\t".$study_encounter_wait_min."\n";
		    print STDERR "\t\t".$study_encounter_wait_var."\n";
		    print STDERR "\t\t".$study_clinical_dx."\n";
		    print STDERR "\t\t".$study_clinical_dx_prob."\n";

		    print STDERR "\t\t".$study_start_epoch."\n";
		    print STDERR "\t\t".$study_end_epoch."\n";
		}
		
		# Get the number of participant
		# p is study participant/subject

		# FOR EACH PARTICIPANT IN THE STUDY
		my $p_max = $study_num_subjects;
		for (my $p=0; $p <= $p_max; $p++) {

		    # GET AN MRN FOR THE SUBJECT
		    my $p_mrn;
		    if ($subjfile) {
			$len_picklist = @subjects;
			if ($len_picklist > 0) {
			    $p_mrn = shift @subjects;
			}
			else {
			    unless ($quiet) {
				warn ("End of picklist. Generating randon MRNs\n");
			    }
			    my $p_mrn_rand = int(rand() * 10000000);
			    $p_mrn = sprintf("%09d", $p_mrn_rand);
			}
			
			
		    }
		    else {
			my $p_mrn_rand = int(rand() * 10000000);
			$p_mrn = sprintf("%09d", $p_mrn_rand);
		    }

		    
		    # Get a study enrollment date for the participant
		    my $epoch_distance = $study_end_epoch - $study_start_epoch;
		    my $rand_epoch_time = int(rand() * $epoch_distance);
		    my $epoch_enroll_date = $study_start_epoch + $rand_epoch_time;
		    my $p_enroll_dt = DateTime->from_epoch( epoch => $epoch_enroll_date );

		    
		    my $p_clinicaldiagid;
		    my $p_clinicaldiagdesc;
		    # Get a diagnosis for the patient
		    if ($study_clinical_dx =~ "null") {
			$p_clinicaldiagid = "null";
			$p_clinicaldiagdesc = "null";
		    } else {
			$p_clinicaldiagid = pick_from_list( $study_clinical_dx, $study_clinical_dx_prob);

			# If the clinical diag includes the code
			if ($p_clinicaldiagid =~ m/(.*)\[(.*)\]/ ) {

			    # Parse out matched values
			    $p_clinicaldiagdesc = $1;
			    $p_clinicaldiagid = $2;

			    # Clean leading and trailing spaces FTW
			    $p_clinicaldiagdesc =~ s/^\s+|\s+$//g;
			    $p_clinicaldiagid =~ s/^\s+|\s+$//g;
			    
			}
			else {
			    $p_clinicaldiagdesc = $p_clinicaldiagid;
			}

			
		    }

		    
		    print STDERR "\t\t\tSubject:".$p."\n" if $verbose;

		    # FOR EACH POTENTIAL SAMPLE FROM THE PARTICIPANT
		    my $s_max = $num_samples - 1;
		    for (my $s=0; $s <= $s_max; $s++) {

			my $s_encounter_num = $study_samples[$s][2];
			my $s_type_id = $study_samples[$s][3];
			my $s_description = $study_samples[$s][4];
			my $s_collection_method = $study_samples[$s][5];
			my $s_probability_collected = $study_samples[$s][6];
			my $s_treatment = $study_samples[$s][7];
			my $s_tissue_id = $study_samples[$s][8];
			my $s_tissue_desc = $study_samples[$s][9];


			# Determine if the sample was made
			my $rand = rand();

			if ($verbose) {
			    print STDERR "\t\t\tENC: ".
				$s_encounter_num."\n";
			    print STDERR "\t\t\tTYP: ".
				$s_type_id."\n";
			    print STDERR "\t\t\tDSC: ".
				$s_description."\n";
			    print STDERR "\t\t\tMTD: ".
				$s_collection_method."\n";
			    print STDERR "\t\t\tPRB: ".
				$s_probability_collected."\n";
			    print STDERR "\t\t\tTRT: ".
				$s_treatment."\n";
			    print STDERR "\t\t\tTID: ".
				$s_tissue_id."\n";
			    print STDERR "\t\t\tTDS: ".
				$s_tissue_desc."\n";
			}

			
			if ( $rand < $s_probability_collected ) {
			    # The rows of the output needed
			    my $u_mrn = $p_mrn;
			    
			    my $epoch_add = $epoch_day * ($s_encounter_num - 1) * $study_encounter_wait_min;

			    # The following gives collection date as epoch time
			    my $collectiondt = $epoch_enroll_date + $epoch_add;
			    # Reality check for collection date out of range


			    my $ev_collect = $collectiondt + 1;
			    my $ev_end = $study_end_epoch + 1;

			    my $time_in_bounds = 1;
			    if ( $collectiondt >  $study_end_epoch ) {
				$time_in_bounds = 0;
			    }
			    
			    
			    # Convert the date to a human readable form
			    # This really just needs to be in a form that Oracle and consume
			    my $dt_obj = DateTime->from_epoch( epoch => $collectiondt);
			    $collectiondt = $dt_obj->month."/".$dt_obj->day."/".$dt_obj->year;

			    
			    my $eventdt = $collectiondt;
			    my $p_enroll_dt;

			    # Sample ID generated from study and row number
			    my $sid_01 = sprintf("%04d", $num_studies);
			    my $sid_02 = sprintf("%06d", $num_rows);
			    my $s_sampleid = "S-".$sid_01."-".$sid_02;
			    
			    my $sampletypeid = $s_type_id;
			    my $collectmethodid = $s_collection_method;
			    my $treatment = $s_treatment;
			    

			    # Set the clinical diagnosis of the sample to the clinical
			    # diagnosis of the patient
			    my $s_clinicaldiagid = $p_clinicaldiagid;
			    my $clinicaldiagdesc = $p_clinicaldiagdesc;
			    
			    my $s_tissueid = $s_tissue_id;
			    my $tissuedesc = $s_tissue_desc;
			    my $sstudyid = $study_id;
			    my $u_pi = $study_pi;


			    # Don't print time out of bounds
			    if ($time_in_bounds) {
				$num_rows++;
				print OUTFILE 
				    $u_mrn."\t".
				    $collectiondt."\t".
				    $eventdt."\t".
				    $s_sampleid."\t".
				    $sampletypeid."\t".
				    $collectmethodid."\t".
				    $treatment."\t".
				    $s_clinicaldiagid."\t".
				    $clinicaldiagdesc."\t".
				    $s_tissueid."\t".
				    $tissuedesc."\t".
				    $sstudyid."\t".
				    $u_pi.
				    "\n";
			    }
			    
			}

			    
			# If we determine we are writing output, increment rows
			
		    }
		    



		    
		}

		
	    }
	    
	    print STDERR "Processing:".$config_parts[0]."\n" unless $quiet;

	    # Get study data from input file
	    $study_id = $config_parts[0];
	    $study_name = $config_parts[1];
	    $study_pi = $config_parts[2];
	    $study_start_date = $config_parts[3];
	    $study_end_date = $config_parts[4];
	    $study_num_subjects = $config_parts[5];
	    $study_encounter_wait_min = $config_parts[6];
	    $study_encounter_wait_var = $config_parts[7];
	    $study_clinical_dx = $config_parts[8];
	    $study_clinical_dx_prob = $config_parts[9];

	    # Get date parts as epoch
	    my ($st_month, $st_day, $st_year) = split (/\//, $study_start_date);
	    my $study_start_dt = DateTime->new(year   => $st_year, 
					       month  => $st_month, 
					       day    => $st_day );
	    $study_start_epoch = $study_start_dt->epoch;
	    my ($end_month, $end_day, $end_year) = split (/\//, $study_end_date);
	    my $study_end_dt = DateTime->new(year   => $end_year, 
					       month  => $end_month, 
					       day    => $end_day );

	    $study_end_epoch = $study_end_dt->epoch;	    
	    
	    push @config_data, @config_parts;
	    @study_samples=();
	    $num_studies++;
	    $num_samples = 0;
	    
	}
	
    }
    
}

# Finished
close (CONFIG);
close (OUTFILE);

unless ($quiet) {
    print STDERR "Finished";
    print STDERR "Rows of Pseudodata:".$num_rows."\n";
}

exit 0;

sub pick_from_list {
    # Assign a category from input as categories
    # and a probability list of the same list.
    # as a list of probabilites for each category.
    
    # $in_picklist is the list of categories
    # $in_probs is the probability for each category being picked

    my ($in_picklist, $in_probs) = @_;

    my @picklist = split (/\|/, $in_picklist);
    my @probs;
    my $pick_value;
    
    # If a probability list is given use this
    # to populate an array of proababilities
    # otherwise pick a value with equal probabilities.
    if ($in_probs) {
	@probs = split(/\|/, $in_probs);
    }
    else {
	$pick_value = $picklist[ rand @picklist ];
	# Clean up any trailing and leading whitespace 
	$pick_value =~ s/^\s+|\s+$//g;
	return $pick_value;
    }

    # Test that the number probs and picks are the same    
    my $num_probs = @probs;
    my $num_picklist = @picklist;
    if ($num_probs != $num_picklist) {
	warn("WARNING : Probabilities and Picklist unequal\n".	     
	     "\t$in_picklist\n\t$in_probs\n");
    }

    # Test that the probabilities sum to one
    my $p_sum= 0;
    my $p_sum_str;
    for (my $i=0; $i<=$num_probs-1; $i++) {
	$p_sum = $p_sum + $probs[$i];
    }
    if ($p_sum != 1) {
	warn("WARNING: Probabilities do not sum to one\n".
	    "\tsum $in_probs is $p_sum\n");
    }
    
    my $rand_num = rand();

    my $bin_low = 0;
    my $bin_high;
    
    for (my $i=0; $i<=$num_probs-1; $i++) {
	$bin_high = $bin_low + $probs[$i];
	
	if ($rand_num <= $bin_high) {
	    if ($rand_num > $bin_low) {
		$pick_value = $picklist[$i];
		# Clean up any trailing and leading whitespace 
		$pick_value =~ s/^\s+|\s+$//g;
		return $pick_value;
	    }
	}
	$bin_low = $bin_high;
	
    }

}


sub print_help {
    my ($help_msg, $podfile) =  @_;
    # help_msg is the type of help msg to use (ie. help vs. usage)
    
    print "\n";
    
    #-----------------------------+
    # PIPE WITHIN PERL            |
    #-----------------------------+
    # This code made possible by:
    # http://www.perlmonks.org/index.pl?node_id=76409
    # Tie info developed on:
    # http://www.perlmonks.org/index.pl?node=perltie 
    #
    #my $podfile = $0;
    my $scalar = '';
    tie *STDOUT, 'IO::Scalar', \$scalar;
    
    if ($help_msg =~ "usage") {
	podselect({-sections => ["SYNOPSIS|MORE"]}, $0);
    }
    else {
	podselect({-sections => ["SYNOPSIS|ARGUMENTS|OPTIONS|MORE"]}, $0);
    }

    untie *STDOUT;
    # now $scalar contains the pod from $podfile you can see this below
    #print $scalar;

    my $pipe = IO::Pipe->new()
	or die "failed to create pipe: $!";
    
    my ($pid,$fd);

    if ( $pid = fork() ) { #parent
	open(TMPSTDIN, "<&STDIN")
	    or die "failed to dup stdin to tmp: $!";
	$pipe->reader();
	$fd = $pipe->fileno;
	open(STDIN, "<&=$fd")
	    or die "failed to dup \$fd to STDIN: $!";
	my $pod_txt = Pod::Text->new (sentence => 0, width => 78);
	$pod_txt->parse_from_filehandle;
	# END AT WORK HERE
	open(STDIN, "<&TMPSTDIN")
	    or die "failed to restore dup'ed stdin: $!";
    }
    else { #child
	$pipe->writer();
	$pipe->print($scalar);
	$pipe->close();	
	exit 0;
    }
    
    $pipe->close();
    close TMPSTDIN;

    print "\n";

    exit 0;
   
}

1;
__END__

=head1 NAME

generate_random_data.pl - Make fake data for testing.

=head1 VERSION

This documentation refers to program version 0.1

=head1 SYNOPSIS

=head2 generate_random_data.pl -i input_mrns.txt -o output.txt

    generate_random_data.pl -s subs.txt -o outfile -c config

=head2 Required Arguments

    --subjects      # Path to the subjects input file (ie. list of fake MRNs)
    --config        # Path to the config file for studies
    --outfile       # Path to the output file, delimited output file

=head1 DESCRIPTION

Generate fake data to simulate a biorepository data store.


=head1 REQUIRED ARGUMENTS

=over 2

=item -i,--infile

Path of the input file containing a set of 'key' values to build false data 
around. The assumption will be to use these as the first column of the output.

=item -c,--config

Path of the config file containing study metadata that will be used to generate the
pseudo data sample.

=item -o,--outfile

Path of the output file, a delimited file of fake datax.

=back

=head1 OPTIONS

=over 2

=item --usage

Short overview of how to use program from command line.

=item --help

Show program usage with summary of options.

=item --version

Show program version.

=item --man

Show the full program manual. This uses the perldoc command to print the 
POD documentation for the program.

=item -q,--quiet

Run the program with no output to STDERR.

=back

=head1 EXAMPLES

The following are examples of how to use this script

=head2 Typical Use

A typcial use of this program is as follows.

 generate_random_data.pl -c config_file.txt -o pseudo_data_out.txt

=head1 DIAGNOSTICS

=over 2

=item * Expecting input from STDIN

If you see this message, it may indicate that you did not properly specify
the input sequence with -i or --infile flag. 

=back

=head1 CONFIGURATION AND ENVIRONMENT

This program does not make use of varaibles set in the user environment. 

The config file used by this program identifies the studies and expected
encounters from a basic experimental design.

=head1 DEPENDENCIES

Other modules or software that the program is dependent on would be listed here.
As currentlly written this program should run on a default Perl installation.

=head1 BUGS AND LIMITATIONS

Any known bugs and limitations will be listed here.

=head1 REFERENCE

None.

=head1 LICENSE

None.

=head1 AUTHOR

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 HISTORY

STARTED: 1/12/2015
 
UPDATED: 1/13/2015

VERSION: $Rev$

=cut

#-----------------------------------------------------------+
# HISTORY                                                   |
#-----------------------------------------------------------+
#
# 1/15/2015
# - Added option to pick from mrn list
