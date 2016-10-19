# kyotoquota
Set disk quota dynamically.

## Summary
The script `adaptquota` adapts the user quota to the amount of free
space that is still left on a disk. When it is below a certain limit,
the script reduces the quota of the users. On the other hand, when it
is larger than another limit, it expands the quota a bit, up to a
pre-set max. The script should be used in a crontab.

## Motivation
The script is ment to ameliorate the *tragedy of the commons* type of
problems in computers that are used by groups. In such a case the
users tend to occupy the full disk-space, making the computer useless.

## Installation

### Pre-requisites
- [Nuweb](nuweb.sourceforge.net)
- M4

### Procedure
1. Clone this repo.
2. Cd to the "nuweb" subdirectory
3. Perform `Make sources`. This results in script "adaptquota" in the
   root directory.

### Adaptation

The nuweb source is located in `nuweb/a_kyotoquota.w`. Parameter
values are located in `nuweb/inst.m4`.


## Documentation
The documentation can be found in `nuweb/kyotoquota.pdf`.



