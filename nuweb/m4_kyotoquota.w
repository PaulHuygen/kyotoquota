m4_include(inst.m4)m4_dnl
\documentclass[twoside]{artikel3}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\renewcommand{\indexname}{General index}
\makeindex
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\title{\thedoctitle}
\author{\theauthor}
\date{m4_docdate}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
  This document generates a script (Bash) that adapts quota settings
  to the amount of free space on the disk.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

When a group of users have a computer in common use, the users tend to
take up all the available disk-space, thereby making the system
useless. It is an example of the ``tragedy of the
commons''\cite{hardin68a}. To avoid this problem, a ``quota'' system
can be set up that limits the the amount of disk-space that a user may
occupy. This document describes and sets up a script that adapts the user-quota
to the amount of disk-space that is still free. Initially, when there is
sufficient disk-space, the quota is set to a large value (``begin-quota''). When the
free disk-space decreases below a given thresholt, the quota-system
sets in and reduces the user-quota slowly until there is enough free
space. When a large fraction of the disk is free, the quota are
gradually increased, until ``begin-quota'' is reached.

The script can be implemented as a ``cron'' task.

In our computer, we discern two user groups, regular users and
students/guest, who may use the computer temporarily for specific
projects. The students are allowed a smaller amount of quota than the
regular users. 


\subsection{Quota settings}
\label{sec:settings}

When there is plenty of free-disk-space, there is no need for a tight
limit. Usually only few users need a really large amount of disk
space, so let us set the absolute maximum quota to one fifth of the
capacity of the disk. Let us assign a max amount of one tenth of that
to students.


@d quota settings @{max_quota_perc=m4_max_quota_perc
max_studquota_perc=m4_max_studquota_perc
@|max_quota_perc max_studquota_perc @}

It is difficult to manipulate floating-point numbers in this script,
therefore we will use percentages. Set the percentage of free space
below which this script will reduce the quota and the percentage above
which the script will possibly increase  the quota:

@d quota settings @{minfreespace_perc=m4_minfreespace_perc
maxfreespace_perc=m4_maxfreespace_perc
@| minfreespace_perc maxfreespace_perc @}

When free space is too little, the script reduces the quota to
\verb|reduction_perc| percent of the original value. When free space is abundant, the script
may expand the quota with \verb|expansion_perc| percent. 

@d quota settings @{reduction_perc=m4_reduction_perc
expansion_perc=m4_expansion_perc
@| reduction_perc expansion_perc @}

The Unix quota system knows, besides the hard limit of allowed
disc-space usage, a soft limit. If a
user exceeds the soft limit, she will get warnings.

@d quota settings @{soft_perc=80
@|soft_perc @}

\subsection{Regular users and students}
\label{sec:userclasses}

The users of the computer are divided up in a group ``user'' (with
group-id m4_usergroup_id) and a group ``studs'' with group-id
m4_studgroup_id. The group-id is the fourth item in the ``passwd
file'' (\verb|/etc/passwd|).

@d variables @{usergroup_id=m4_usergroup_id
studgroup_id=m4_studgroup_id
@| usergroup_id studgroup_id @}

To find a username and a group-id in a line of \verb|/etc/passwd|, the
following macro's can be used. The first argument (\verb|@@1|)
represents the line from \verb|/etc/passwd| and the second argument
represents the username resp. group-id:

@d find username in line of password-file @{@2=`echo @1 | gawk '{print $1}' FS=':'`
@| @}

@d find group-id in line of password-file @{@2=`echo @1 | gawk '{print $4}' FS=':'`
@| @}



\subsection{The quota system}
\label{sec:quota-system}


The command \verb|getquota|  obtains information about the quota of
users/ The following shows an example of use:

\begin{verbatim}
huygen@@kyoto:~/projecten/kyoto/quota/kyotoquota/nuweb$ sudo repquota / 
[sudo] password for huygen: 
*** Report for user quotas on device /dev/vda3
Block grace time: 00:00; Inode grace time: 00:00
                        Block limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
[..]
brasser   --  554012 81895040  102368800          3241     0     0       
vossen    -- 29239788 81895040  102368800        107543     0     0       
segers    --  189764 81895040  102368800            38     0     0       

\end{verbatim}


So, command results in a table in which the name of the user is in the
first column, the ``soft block-limit'' in the fourth column and the
``hard block limit'' in the fifth column.

Hence, to obtain the current hard block-limit of a user, find the
fifth column in the line that starts with the name of the user:

@d get hard quotum of user @{@2=`repquota -vu / | grep "@1" | gawk '{print $5}'`
@| @}


Modify the quota of a user with the following macro. Arguments
\begin{enumerate}
\item (\verb|@@1|) Name of the user. 
\item soft block-quotum
\item hard block-quotum
\end{enumerate}

@d set quota of a user @{setquota -u @1 @2 @3 0 0 /
@| setquota @}



\section{The script}
\label{sec:script}

The script works as follows:

\begin{itemize}
\item Find out the amount of free diskspace.
\item Determine whether the quota must be reduced or increased.
\item If so, perform the change.
\end{itemize}

@o m4_projroot/adaptquota @{#!/bin/bash
# adaptquota -- adapt user-quota to amount of free disk space
@< variables @>
@< quota settings @>
@< find out free diskspace @>
@< determine whether quota should be reduced or possibly expanded @>
@< expand or reduce quota @>
@| @}


\subsection{Find out free disk-space}
\label{sec:findout-free-space}

Use Unix command \verb|df| to find out the capacity of the disk and
the amount of disk-space that is still free. An example of the result
of the \verb|df| command:

\begin{verbatim}
huygen@@kyoto:~$ df /dev/vda3
Filesystem     1K-blocks      Used Available Use% Mounted on
/dev/vda3      511844016 406344896  79475852  84% /
huygen@@kyoto:~$ 

\end{verbatim}


So, it seems that the second word of the second line of the output
gives us the total disk capacity and the fourth word gives us the
remaining capacity.

@d find out free diskspace @{disk_capacity=`df m4_device 2>/dev/null | gawk 'NR==2 {print $2}'`
disk_free=`df m4_device 2>/dev/null | gawk 'NR==2 {print $4}'`
@| disk_capacity disk_free @}

To perform integer arithmatic with the obtained data, let us create
variables that represent one percent of the capacity. To do this, chop
off the two rightmost digits:

@d find out free diskspace @{disk_capacity_onep=${disk_capacity%??}
disk_free_onep=${disk_free%??}
@| disk_capacity_onep disk_free_onep @}

Define \verb|min-diskfree|, the amount of free disk-space below which
the quota will be restricted and \verb|max-diskfree| above which the
quota might be expanded.

@d find out free diskspace @{min_diskfree=$((minfreespace_perc*$disk_capacity_onep))
max_diskfree=$((maxfreespace_perc*$disk_capacity_onep))
@|min_diskfree max_diskfree @}

\subsection{Determine whether quota should be expanded or reduced}
\label{sec:find_out_expand_reduce}

Varianble \verb|change| is going to indicate whether we have to
increase or decrease quota.

@d determine whether quota should be reduced or possibly expanded @{change="No"
if
  [ $disk_free -lt $min_diskfree ]
then
  change="Dec"
elif
  [ $disk_free -gt $max_diskfree ]
then
  change="Inc"
fi
@|change @}

\subsection{Change the quota}
\label{sec:changequota}

If we have to change the quota, we must first find out what the quota
currently are, then calculate what the quota should be, and finally
set the new quota.

Note, that when variable \verb|change| tells us to increase the quota,
it is possible that we do not want to do that because the quota have
already reached their maximum values. In that case, we set the new
value for the quotum equal to the current value.

@d expand or reduce quota @{if
  [ ! "$change" == "No" ]
then
  @< find out what the quota currently are @>
  @< calculate new quota @>
  if [ ! $new_hardquotum == $current_quotum ]
  then
    @< activate new quota @>
  fi
fi
@| @}

To find out what the quota currently are, find the quota of a random regular
user:
\begin{itemize}
\item Find the name of a user of the ``user'' group in \verb|/etc/passwd|.
\item Find her quota in a ``quota report''.
\end{itemize}

@d find out what the quota currently are @{@< find the name of a regular user @(sixpack@) @>
@< get hard quotum of user @($sixpack@,current_quotum@) @>
@| current_quotum, sixpack @}

@d find the name of a regular user @{while
  read line
do
    @< find username in line of password-file @($line@,user@) @>
    @< find group-id in line of password-file @($line@,group_id@) @>
    if
      [ $group_id -eq $usergroup_id ]
    then
      @1=$user
      break
    fi
done < /etc/passwd
@| @}

If the quota should be reduced, multiply the current hard-quotum with
the decrease-fraction. If the quota might possibly be increased,
first look whether the quotum has not yet attained its max. 

@d calculate new quota @{current_quotum_onep=${current_quotum%??}
if
  [ "$change" == "Dec" ]
then
  new_hardquotum=$((reduction_perc*current_quotum_onep))
else
  new_hardquotum=$current_quotum
  max_hardquotum=$((max_quota_perc*$max_capacity_onep))
  if
    [ $current_quotum -lt $max_hardquotum ]
  then
    new_hardquotum=$((expansion_perc*current_quotum_onep))
  fi
fi
@| @}

We have to set a soft-max and a quota for students. When a user
occupies more diskspace than the the soft-max limit, she wil get
warnings. 

@d calculate new quota @{new_hardquotum_onep=${new_hardquotum%??}
new_softquotum=$((soft_perc*$new_hardquotum_onep))
@| @}

@d calculate new quota @{new_hardquotum_studs=$((10*$new_hardquotum_onep))
new_softquotum_studs=$((8*$new_hardquotum_onep))
@| @}


\subsection{Activate new quota}
\label{sec:activate}

Find the names of regular and student users and set the quota for
each of them.

@d activate new quota @{while
  read line
do
  @< find username in line of password-file @($line@,user@) @>
  @< find group-id in line of password-file @($line@,group_id@) @>
  if
    [ $group_id == $usergroup_id ]
  then
    @< set quota of a user @($user@,$new_softquotum@,$new_hardquotum@) @>
  elif
    [ $group_id == $studgroup_id ]
  then
    @< set quota of a user @($user@,$new_softquotum_studs@,$new_hardquotum_studs@) @>
  fi
done < /etc/passwd
@| @}

It seems that the quotacheck program has to be performed after
modifying quota.

@d activate new quota @{quotaoff /
quotacheck -vgum /
quotaon /
@| quotaon quotacheck quotaon @}
  



\appendix

\section{How to read and translate this document}
\label{sec:translatedoc}

This document is an example of \emph{literate
  programming}~\cite{Knuth:1983:LP}. It contains the code of all sorts
of scripts and programs, combined with explaining texts. In this
document the literate programming tool \texttt{nuweb} is used, that is
currently available from Sourceforge
(URL:\url{m4_nuwebURL}). The advantages of Nuweb are, that
it can be used for every programming language and scripting language, that
it can contain multiple program sources and that it is very simple.


\subsection{Read this document}
\label{sec:read}

The document contains \emph{code scraps} that are collected into
output files. An output file (e.g. \texttt{output.fil}) shows up in the text as follows:

\begin{alltt}
"output.fil" \textrm{4a \(\equiv\)}
      # output.fil
      \textrm{\(<\) a macro 4b \(>\)}
      \textrm{\(<\) another macro 4c \(>\)}
      \(\diamond\)

\end{alltt}

The above construction contains text for the file. It is labelled with
a code (in this case 4a)  The constructions between the \(<\) and
\(>\) brackets are macro's, placeholders for texts that can be found
in other places of the document. The test for a macro is found in
constructions that look like:

\begin{alltt}
\textrm{\(<\) a macro 4b \(>\) \(\equiv\)}
     This is a scrap of code inside the macro.
     It is concatenated with other scraps inside the
     macro. The concatenated scraps replace
     the invocation of the macro.

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}

Macro's can be defined on different places. They can contain other macro´s.

\begin{alltt}
\textrm{\(<\) a scrap 87e \(>\) \(\equiv\)}
     This is another scrap in the macro. It is
     concatenated to the text of scrap 4b.
     This scrap contains another macro:
     \textrm{\(<\) another macro 45b \(>\)}

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}


\subsection{Process the document}
\label{sec:processing}

The raw document is named
\verb|a_<!!>m4_progname<!!>.w|. Figure~\ref{fig:fileschema}
\begin{figure}[hbtp]
  \centering
  \includegraphics{fileschema.fig}
  \caption{Translation of the raw code of this document into
    printable/viewable documents and into program sources. The figure
    shows the pathways and the main files involved.}
  \label{fig:fileschema}
\end{figure}
 shows pathways to
translate it into printable/viewable documents and to extract the
program sources. Table~\ref{tab:transtools}
\begin{table}[hbtp]
  \centering
  \begin{tabular}{lll}
    \textbf{Tool} & \textbf{Source} & \textbf{Description} \\
    gawk  & \url{www.gnu.org/software/gawk/}& text-processing scripting language \\
    M4    & \url{www.gnu.org/software/m4/}& Gnu macro processor \\
    nuweb & \url{nuweb.sourceforge.net} & Literate programming tool \\
    tex   & \url{www.ctan.org} & Typesetting system \\
    tex4ht & \url{www.ctan.org} & Convert \TeX{} documents into \texttt{xml}/\texttt{html}
  \end{tabular}
  \caption{Tools to translate this document into readable code and to
    extract the program sources}
  \label{tab:transtools}
\end{table}
lists the tools that are
needed for a translation. Most of the tools (except Nuweb) are available on a
well-equipped Linux system.


@d parameters in Makefile @{NUWEB=m4_nuwebbinary
@| @}


\subsection{Translate and run}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@< default target @>

@< parameters in Makefile @> 

@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

The default target of make is \verb|all|.

@d  default target @{all : @< all targets @>
.PHONY : all

@|PHONY all @}


One of the targets is certainly the \textsc{pdf} version of this
document.

@d all targets @{m4_progname.pdf@}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{.SUFFIXES: .pdf .w .tex .html .aux .log .php

@| SUFFIXES @}



\subsection{Pre-processing}
\label{sec:pre-processing}

To make usable things from the raw input \verb|a_<!!>m4_progname<!!>.w|, do the following:

\begin{enumerate}
\item Process \verb|$| characters.
\item Run the m4 pre-processor.
\item Run nuweb.
\end{enumerate}

This results in a \LaTeX{} file, that can be converted into a \pdf{}
or a \HTML{} document, and in the program sources and scripts.

\subsubsection{Process `dollar' characters }
\label{sec:procdollars}

Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
Emacs) handle \verb|$| characters as special, to switch into
mathematics mode. This is irritating in program texts, that often
contain \verb|$| characters as well. Therefore, we make a stub, that
translates the two-character sequence \verb|\$| into the single
\verb|$| character.


@d expliciete make regels @{m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\$$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w

@| @}


\subsubsection{Run the M4 pre-processor}
\label{sec:run_M4}

@d  expliciete make regels @{m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}


\subsection{Typeset this document}
\label{sec:typeset}

Enable the following:
\begin{enumerate}
\item Create a \pdf{} document.
\item Print the typeset document.
\item View the typeset document with a viewer.
\item Create a \HTML document.
\end{enumerate}

In the three items, a typeset \pdf{} document is required or it is the
requirement itself.




\subsubsection{Figures}
\label{sec:figures}

This document contains figures that have been made by
\texttt{xfig}. Post-process the figures to enable inclusion in this
document.

The list of figures to be included:

@d parameters in Makefile @{FIGFILES=fileschema

@| FIGFILES @}

We use the package \texttt{figlatex} to include the pictures. This
package expects two files with extensions \verb|.pdftex| and
\verb|.pdftex_t| for \texttt{pdflatex} and two files with extensions \verb|.pstex| and
\verb|.pstex_t| for the \texttt{latex}/\texttt{dvips}
combination. Probably tex4ht uses the latter two formats too.

Make lists of the graphical files that have to be present for
latex/pdflatex:

@d parameters in Makefile @{FIGFILENAMES=$(foreach fil,$(FIGFILES), $(fil).fig)
PDFT_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex_t)
PDF_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex)
PST_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex_t)
PS_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex)

@|FIGFILENAMES PDFT_NAMES PDF_FIG_NAMES PST_NAMES PS_FIG_NAMES@}


Create
the graph files with program \verb|fig2dev|:

@d impliciete make regels @{%.eps: %.fig
	fig2dev -L eps $< > $@@

%.pstex: %.fig
	fig2dev -L pstex $< > $@@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p $*.pstex $< > $@@

%.pdftex: %.fig
	fig2dev -L pdftex $< > $@@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p $*.pdftex $< > $@@

@| fig2dev @}


\subsubsection{Bibliography}
\label{sec:bbliography}

To keep this document portable, create a portable bibliography
file. It works as follows: This document refers in the
\texttt|bibliography| statement to the local \verb|bib|-file
\verb|m4_progname.bib|. To create this file, copy the auxiliary file
to another file \verb|auxfil.aux|, but replace the argument of the
command \verb|\bibdata{m4_progname}| to the names of the bibliography
files that contain the actual references (they should exist on the
computer on which you try this). This procedure should only be
performed on the computer of the author. Therefore, it is dependent of
a binary file on his computer.


@d expliciete make regels @{bibfile : m4_progname.aux m4_mkportbib
	m4_mkportbib m4_progname m4_bibliographies

.PHONY : bibfile
@| @}

\subsubsection{Create a printable/viewable document}
\label{sec:createpdf}

Make a \pdf{} document for printing and viewing.

@d make targets @{pdf : m4_progname.pdf

print : m4_progname.pdf
	m4_printpdf(m4_progname)

view : m4_progname.pdf
	m4_viewpdf(m4_progname)

@| pdf view print @}

Create the \pdf{} document. This may involve multiple runs of nuweb,
the \LaTeX{} processor and the bib\TeX{} processor, and depends on the
state of the \verb|aux| file that the \LaTeX{} processor creates as a
by-product. Therefore, this is performed in a separate script,
\verb|w2pdf|.

\paragraph{The w2pdf script}
\label{sec:w2pdf}

The three processors nuweb, \LaTeX{} and bib\TeX{} are
intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
value of parameters, and write them in an auxiliary file. The other
processors may need those values to produce the correct output. The
\LaTeX{} processor may even need the parameters in a second
run. Therefore, consider the creation of the (\pdf) document finished
when none of the processors causes the auxiliary file to change. This
is performed by a shell script \verb|w2pdf|.




Note, that in the following \texttt{make} construct, the implicit rule
\verb|.w.pdf| is not used. It turned out, that make did not calculate
the dependencies correctly when I did use this rule.

@d  impliciete make regels@{%.pdf : %.w $(W2PDF)  $(PDF_FIG_NAMES) $(PDFT_NAMES) %.bib
	chmod 775 $(W2PDF)
	$(W2PDF) $*

@| @}

The following is an ugly fix of an unsolved problem. Currently I
develop this thing, while it resides on a remote computer that is
connected via the \verb|sshfs| filesystem. On my home computer I
cannot run executables on this system, but on my work-computer I
can. Therefore, place the following script on a local directory.

@d parameters in Makefile @{W2PDF=m4_nuwebbindir/w2pdf
@| @}

@d directories to create @{m4_nuwebbindir @| @}

@d expliciete make regels  @{$(W2PDF) : m4_progname.w
	$(NUWEB) m4_progname.w
@| @}

m4_dnl
m4_dnl Open compile file.
m4_dnl args: 1) directory; 2) file; 3) Latex compiler
m4_dnl
m4_define(m4_opencompilfil,
<!@o !>$1<!!>$2<! @{#!/bin/bash
# !>$2<! -- compile a nuweb file
# usage: !>$2<! [filename]
# !>m4_header<!
NUWEB=m4_nuwebbinary
LATEXCOMPILER=!>$3<!
@< filenames in nuweb compile script @>
@< compile nuweb @>

@| @}
!>)m4_dnl

m4_opencompilfil(<!m4_nuwebbindir/!>,<!w2pdf!>,<!pdflatex!>)m4_dnl


The script retains a copy of the latest version of the auxiliary file.
Then it runs the four processors nuweb, \LaTeX{}, MakeIndex and bib\TeX{}, until
they do not change the auxiliary file or the index. 

@d compile nuweb @{NUWEB=m4_nuweb
@< run the processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}

The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in nuweb compile script @{nufil=$1
trunk=${1%%.*}
texfil=${trunk}.tex
auxfil=${trunk}.aux
oldaux=old.${trunk}.aux
indexfil=${trunk}.idx
oldindexfil=old.${trunk}.idx
@| nufil trunk texfil auxfil oldaux indexfil oldindexfil @}

Remove the old copy if it is no longer needed.
@d remove the copy of the aux file @{rm $oldaux
@| @}

Run the three processors. Do not use the option \verb|-o| (to suppres
generation of program sources) for nuweb,  because \verb|w2pdf| must
be kept up to date as well.

@d run the three processors @{$NUWEB $nufil
$LATEXCOMPILER $texfil
makeindex $trunk
bibtex $trunk
@| nuweb makeindex bibtex @}


Repeat to copy the auxiliary file and the index file  and run the processors until the
auxiliary file and the index file are equal to their copies.
 However, since I have not yet been able to test the \verb|aux|
file and the \verb|idx| in the same test statement, currently only the
\verb|aux| file is tested.

It turns out, that sometimes a strange loop occurs in which the
\verb|aux| file will keep to change. Therefore, with a counter we
prevent the loop to occur more than m4_maxtexloops times.

@d run the processors until the aux file remains unchanged @{LOOPCOUNTER=0
while
  ! cmp -s $auxfil $oldaux 
do
  if [ -e $auxfil ]
  then
   cp $auxfil $oldaux
  fi
  if [ -e $indexfil ]
  then
   cp $indexfil $oldindexfil
  fi
  @< run the three processors @>
  if [ $LOOPCOUNTER -ge 10 ]
  then
    cp $auxfil $oldaux
  fi;
done
@| @}


\subsubsection{Create HTML files}
\label{sec:createhtml}

\textsc{Html} is easier to read on-line than a \pdf{} document that
was made for printing. We use \verb|tex4ht| to generate \HTML{}
code. An advantage of this system is, that we can include figures
in the same way as we do for \verb|pdflatex|.

Nuweb creates a \LaTeX{} file that is suitable
for \verb|latex2html| if the source file has \verb|.hw| as suffix instead of
\verb|.w|. However, this feature is not compatible with tex4ht.

Make html file:

@d make targets @{html : m4_htmltarget

@| @}

The \HTML{} file depends on its source file and the graphics files.

Make lists of the graphics files and copy them.

@d parameters in Makefile @{HTML_PS_FIG_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex)
HTML_PST_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex_t)
@| @}


@d impliciete make regels @{m4_htmldocdir/%.pstex : %.pstex
	cp  $< $@@

m4_htmldocdir/%.pstex_t : %.pstex_t
	cp  $< $@@

@| @}

Copy the nuweb file into the html directory.

@d expliciete make regels @{m4_htmlsource : m4_progname.w
	cp  m4_progname.w m4_htmlsource

@| @}

We also need a file with the same name as the documentstyle and suffix
\verb|.4ht|. Just copy the file \verb|report.4ht| from the tex4ht
distribution. Currently this seems to work.

@d expliciete make regels @{m4_4htfildest : m4_4htfilsource
	cp m4_4htfilsource m4_4htfildest

@| @}

Copy the bibliography.

@d expliciete make regels  @{m4_htmlbibfil : m4_anuwebdir/m4_progname.bib
	cp m4_anuwebdir/m4_progname.bib m4_htmlbibfil

@| @}



Make a dvi file with \texttt{w2html} and then run
\texttt{htlatex}. 

@d expliciete make regels @{m4_htmltarget : m4_htmlsource m4_4htfildest $(HTML_PS_FIG_NAMES) $(HTML_PST_NAMES) m4_htmlbibfil
	cp w2html m4_abindir
	cd m4_abindir && chmod 775 w2html
	cd m4_htmldocdir && m4_abindir/w2html m4_progname.w

@| @}

Create a script that performs the translation.



@o w2html @{#!/bin/bash
# w2html -- make a html file from a nuweb file
# usage: w2html [filename]
#  [filename]: Name of the nuweb source file.
`#' m4_header
echo "translate " $1 >w2html.log
NUWEB=m4_nuwebbinary
@< filenames in w2html @>

@< perform the task of w2html @>

@| @}

The script is very much like the \verb|w2pdf| script, but at this
moment I have still difficulties to compile the source smoothly into
\textsc{html} and that is why I make a separate file and do not
recycle parts from the other file. However, the file works similar.


@d perform the task of w2html @{@< run the html processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}


The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in w2html @{nufil=$1
trunk=${1%%.*}
texfil=${trunk}.tex
auxfil=${trunk}.aux
oldaux=old.${trunk}.aux
indexfil=${trunk}.idx
oldindexfil=old.${trunk}.idx
@| nufil trunk texfil auxfil oldaux @}

@d run the html processors until the aux file remains unchanged @{while
  ! cmp -s $auxfil $oldaux 
do
  if [ -e $auxfil ]
  then
   cp $auxfil $oldaux
  fi
  @< run the html processors @>
done
@< run tex4ht @>

@| @}


To work for \textsc{html}, nuweb \emph{must} be run with the \verb|-n|
option, because there are no page numbers.

@d run the html processors @{$NUWEB -o -n $nufil
latex $texfil
makeindex $trunk
bibtex $trunk
htlatex $trunk
@| @}


When the compilation has been satisfied, run makeindex in a special
way, run bibtex again (I don't know why this is necessary) and then run htlatex another time.
@d run tex4ht @{m4_index4ht
makeindex -o $trunk.ind $trunk.4dx
bibtex $trunk
htlatex $trunk
@| @}


\paragraph{create the program sources}
\label{sec:createsources}

Run nuweb, but suppress the creation of the \LaTeX{} documentation.
Nuweb creates only sources that do not yet exist or that have been
modified. Therefore make does not have to check this. However,
``make'' has to create the directories for the sources if they
do not yet exist.
So, let's create the directories first.

@d parameters in Makefile @{MKDIR=mkdir -p

@| MKDIR @}



@d make targets @{DIRS=@< directories to create @>

$(DIRS) : 
	$(MKDIR) $@@

@| DIRS @}


@d make targets @{sources : m4_progname.w $(DIRS)
	$(NUWEB) m4_progname.w
	cd .. && chmod 775 adaptquota

jetty : sources
	cd .. && mvn jetty:run

@| @}



\section{References}
\label{sec:references}

\subsection{Literature}
\label{sec:literature}

\bibliographystyle{plain}
\bibliography{m4_progname}

\subsection{URL's}
\label{sec:urls}

\begin{description}
\item[Nuweb:] \url{m4_nuwebURL}
\item[Apache Velocity:] \url{m4_velocityURL}
\item[Velocitytools:] \url{m4_velocitytoolsURL}
\item[Parameterparser tool:] \url{m4_parameterparserdocURL}
\item[Cookietool:] \url{m4_cookietooldocURL}
\item[VelocityView:] \url{m4_velocityviewURL}
\item[VelocityLayoutServlet:] \url{m4_velocitylayoutservletURL}
\item[Jetty:] \url{m4_jettycodehausURL}
\item[UserBase javadoc:] \url{m4_userbasejavadocURL}
\item[VU corpus Management development site:] \url{http://code.google.com/p/vucom} 
\end{description}

\section{Indexes}
\label{sec:indexes}


\subsection{Filenames}
\label{sec:filenames}

@f

\subsection{Macro's}
\label{sec:macros}

@m

\subsection{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 

% LocalWords:  Webcom
