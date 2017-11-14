


GPG Notes

The server that runs this backup needs to have
Encryption key (public)
Signing Key (private & public)

Likely you will have both.

When generating keys, be careful on a VM where there is no way to get more entropy. Install 'haveged' to remedy this.
    Debian/Ubuntu: sudo apt-get install haveged && haveged -F
    Docker: docker run --privileged -d harbur/haveged
    
