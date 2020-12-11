---
title: "HackTheBox: Writeup"
date: 2020-05-23
draft: false
---
### [](#header-3)Box Type: Linux
## [](#header-1)Getting User
Nmap scan showed ports 22 and 80 open.
![](/assets/2020-5-23-HTB-Writeup/Capture.PNG)

Checking out the website shows a notification that some sort of DoS protection is running on the webserver, likely preventing any dictionary or brute force attacks, which means no dirb :(.
![](/assets/2020-5-23-HTB-Writeup/Capture2.PNG)

The Nmap scan did show a robots.txt, however:
![](/assets/2020-5-23-HTB-Writeup/Capture3.PNG)

Navigating to /writeup shows a home page with writeups for other retired boxes:
![](/assets/2020-5-23-HTB-Writeup/Capture4.PNG)

Using wappalyzer, it showed that this webpage was running "CMS Made Simple". Wappalyzer is a useful extension (available for chrome and firefox) which shows what various services, languages, operating system the current website is running.
![](/assets/2020-5-23-HTB-Writeup/Capture5.PNG)

A bit of googling on "CMS Made Simple" showed an [SQL Injection vulnerability](https://www.exploit-db.com/exploits/46635), specifically a blind, time-based injection. Essentially what this means is that we don't recieve any direct output from the injection (blind), so we have to use sleep functionality (time-based) in SQL along with the substring function to determine the trueness of each guess. Through this, we are able to determine valuable information stored on the machine's database, including the Password hash, the salt for the password, the username, and the email related to that user. With this, we can crack the hash using either hashcat or johntheripper and a common wordlist (rockyou.txt), but luckily the exploit found on exploitdb does this all for us. All we have to do is specify the url (http://10.10.10.138/writeup) and the wordlist to use.
![](/assets/2020-5-23-HTB-Writeup/Capture6.PNG)

We now have the username and password for the user "jkr". We can SSH in and get the user.txt flag.
![](/assets/2020-5-23-HTB-Writeup/Capture7.PNG)

## [](#header-2)Getting Root

A common script I like to run on any linux box is "pspy", which shows processes and commands being run in real time. This is useful to see if anything weird is being triggered by doing certain tasks. I used scp to transfer the pspy script over and ran it in one tab. I then opened another SSH connection in another tab to start hopefully triggering some events. Luckily, it was quite easy to find the right event to trigger, since actually SSHing into the box triggered some interesting commands.
![](/assets/2020-5-23-HTB-Writeup/Capture8.PNG)

It's running a command called "run-parts" but it's specifying it's own $PATH environment variable. Well let's check what groups our user is in and what permissions it has on some of these paths:
![](/assets/2020-5-23-HTB-Writeup/Capture9.PNG)

As you can see we are in the "staff" group and staff has write permissions on "/usr/local/sbin", which is the first path specified in the $PATH variable that we saw. Because of this, we can create our own "run-parts" file, have it do whatever we want, place it in /usr/local/sbin and our file will be executed instead of the expected one. This is because Unix will go down the list of the $PATH environment variable until it hits a match. This is what my "run-parts" file looks like:
![](/assets/2020-5-23-HTB-Writeup/Capture12.PNG)

Through a little troubleshooting of my own, I was able to figure out that the /root directory didn't have a .ssh directory, which is why I had it make one in my run-parts file. I then copied by public SSH key over into the root's authorized_keys file and bam, I can now SSH in as root:
![](/assets/2020-5-23-HTB-Writeup/Capture11.PNG)

Overall, this is a really good beginner box, as it points out some common web attacks and enumerations (checking robots.txt and SQL Injection). The priv esc was also a good starter as it points out a simple, yet common vulnerability, which is allowing paths in $PATH to be writable by unauthorized users.

Hope you enjoyed and learned something :)
