# A Perl module implementing a basic config file handling functionality.
#
# Copyright (C) 2013  Yann Riou <yaribzh@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package SimpleConf;

use strict;

use FileHandle;

sub readConf {
  my ($file,$p_conf)=@_;
  my $fh=new FileHandle($file,'r');
  if(! defined $fh) {
    print "ERROR - Unable to read configuration file \"$file\" ($!)\n";
    exit 1;
  }
  my $strictMode=0;
  $strictMode=1 if(%{$p_conf});
  while(<$fh>) {
    next if(/^\s*(\#.*)?$/);
    if(/^\s*([^:]*[^:\s])\s*:\s*(.*[^\s])\s*$/) {
      my ($param,$value)=($1,$2);
      if($param =~ /^([^\.]+)\.(.+)$/) {
        my $subParam;
        ($param,$subParam)=($1,$2);
        if($strictMode) {
          if(! exists $p_conf->{$param} || ref($p_conf->{$param}) ne 'HASH' || ! exists $p_conf->{$param}->{$subParam}) {
            print "ERROR - Invalid setting \"$param.$subParam\" in configuration file \"$file\"\n";
            exit 1;
          }
        }else{
          $p_conf->{$param}={} unless(exists $p_conf->{$param});
          if(ref($p_conf->{$param}) ne 'HASH') {
            print "ERROR - Settings conflict between \"$param\" and \"$param.$subParam\" in configuration file \"$file\"\n";
            exit 1;
          }
        }
        $p_conf->{$param}->{$subParam}=$value;
      }else{
        if($strictMode && ! exists $p_conf->{$param}) {
          print "ERROR - Invalid setting \"$param\" in configuration file \"$file\"\n";
          exit 1;
        }
        $p_conf->{$param}=$value;
      }
    }else{
      s/[\cJ\cM]*$//;
      print "ERROR - Invalid line \"$_\" in configuration file \"$file\"\n";
      exit 1;
    }
  }
  $fh->close();
  foreach my $param (keys %{$p_conf}) {
    if(! defined $p_conf->{$param}) {
      print "ERROR - Missing mandatory setting \"$param\" in configuration file \"$file\"\n";
      exit 1;
    }
    if(ref($p_conf->{$param}) eq 'HASH') {
      foreach my $k (keys %{$p_conf->{$param}}) {
        if(! defined $p_conf->{$param}->{$k}) {
          print "ERROR - Missing mandatory setting \"$param.$k\" in configuration file \"$file\"\n";
          exit 1;
        }
      }
    }
  }
}

sub writeConf {
  my ($file,$p_conf)=@_;
  my @confLines;
  foreach my $param (sort keys %{$p_conf}) {
    next unless(defined $p_conf->{$param});
    if(ref($p_conf->{$param}) eq 'HASH') {
      foreach my $subParam (sort keys %{$p_conf->{$param}}) {
        next unless(defined $p_conf->{$param}->{$subParam});
        push(@confLines,"$param.$subParam:$p_conf->{$param}->{$subParam}");
      }
    }else{
      push(@confLines,"$param:$p_conf->{$param}");
    }
  }
  my $fh=new FileHandle($file,'w');
  if(! defined $fh) {
    print "ERROR - Unable to write configuration file \"$file\" ($!)\n";
    exit 1;
  }
  foreach my $line (@confLines) {
    print $fh "$line\n";
  }
  $fh->close();
}

1;
