# ------------------------------------------------------------------------------
# Copyright 2013 Frank Breedijk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package SeccubusUsers;

use SeccubusRights;
use SeccubusDB;

=head1 NAME $RCSfile: SeccubusUsers.pm,v $

This Pod documentation generated from the module Seccubus_Users gives a list of 
all functions within the module

=cut

@ISA = ('Exporter');

@EXPORT = qw ( 
	get_user_id
	add_user 
	get_login
	get_users
);

use strict;
use Carp;

sub get_user_id($);
sub add_user($$$);
sub get_login();

=head1 User manipulation

=head2 get_user_id
 
This function looks up the numeric user_id based on the username

=over 2

=item Parameters

=over 4

p
=item user - username

=back

=item Checks

None

=back 

=cut 

sub get_user_id($) {
	my $user = shift;
	confess "No username specified" unless $user;

	my $id = sql ( "return"	=> "array",
		       "query"	=> "select id from users where username = ?",
		       "values" => [ $user ],
		     );

	if ( $id ) {
		return $id;
	} else {
		confess("Could not find a userid for user '$user'");
	}
}

=head2 add_user
 
This function adds a use to the users table and makes him member of the all 
group. 

=over 2

=item Parameters

=over 4

=item user - username

=item name - "real" name of the user

=item isadmin - indicates that the user is an admin (optional)

=back

=item Checks

In order to run this function you must be an admin

=back 

=cut 

sub add_user($$$) {
	my $user = shift;
	my $name = shift;
	my $isadmin = shift;

	my ( $id );

	confess "No userid specified" unless $user;
	confess "No naem specified for user $user" unless $name;

	if ( is_admin() ) {
		my $id = sql(	"return"	=> "id",
				"query"		=> "INSERT into users (`username`, `name`) values (? , ?)",
				"values"	=> [$user, $name],
			    );
		#Make sure member of the all group
		sql("return"	=> "id",
		    "query"	=> "INSERT into user2group values (?, ?)",
		    "values"	=> [$id, 2],
	 	   );
		if ( $isadmin ) {
			# Make user meber of the admins group
			sql("return"	=> "id",
			    "query"	=> "INSERT into user2group values (?, ?)",
			    "values"	=> [$id, 1],
			   );
		}
	}
}

=head2 get_users
 
This function returns the users in the database with their groups

=over 2

=item Parameters

None

=item Checks

Must be and admin to use this function

=item Returns

=over 4

=item Username

=item Name

=item Groups

=back 

=back 

=cut 

sub get_users() {
	if ( is_admin() ) {
		my @result;
		my $users = sql(
			"return"	=> "ref",
			"query"		=> "SELECT users.id, users.username, users.name, 
									groups.id as groupid, groups.name as groupname
			                FROM   users, user2group, groups 
			                WHERE  user2group.user_id = users.id 
			                	AND user2group.group_id = groups.id 
			                ORDER BY username, groupname",
		);

		my $u = {};
		foreach my $user ( @$users ) {
			if ( $u->{id} != $$user[0] ) {
				push @result, $u if exists $u->{id};
				$u = {};
				$u->{id} = $$user[0];
				$u->{username} = $$user[1];
				$u->{name} = $$user[2];
				$u->{groups} = ();
			}
			my %g;
			$g{id} = $$user[3];
			$g{name} = $$user[4];
			push @{$u->{groups}}, \%g;
		}

		return \@result;
	} else {
		return undef;
	}
}


# Close the PM file.
return 1;
