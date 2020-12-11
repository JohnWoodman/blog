---
title: "The Most Fun (and maybe impractical) Command and Control: SpotifyC2"
date: 2019-12-22
draft: false
---

Command and Control is one of the most common techniques used by attackers to maintain persistent control over an infected computer, sending commands to be executed and receiving the output of those commands. There exists many different methods for implementing Command and Control, from using cloud services (AWS, Azure, etc.) to even using social media to send commands. One method we will be exploring is one I haven't seen before (probably for a good reason): using Spotify to send commands and receive output.

## [](#header-1)Introduction

My good friend Terry Thibault ([@defnotprobro](https://twitter.com/defnotprobro)) inspired this project, where he presented a talk at BSides Orlando, leveraging Twitter as a method for Command and Control.

Command and Control essentially functions through a backdoor running on the infected machine, beaconing out every once in a while to retrieve a command or a set of commands to be executed. Commands sent to the beacon are usually encoded or hidden in some way (base64, hidden in an image, etc.) to make it harder for someone to detect. My method uses acrostics in Spotify playlist tracks to send commands, and retrieves output through the description box available in those playlists.

I developed multiple scripts to form a proof-of-concept:

[SpotifyC2](https://github.com/JohnWoodman/SpotifyC2)

I use Spotify's API for creating and editing the playlists. If you'd like to use SpotifyC2 yourself, you'll need to place your own client ID, secret, and refresh token in the scripts.

## [](#header-2)Breakdown

Below is a breakdown of the Command and Control process using SpotifyC2.

### [](#header-3)Generating & Sending The Acrostic Command

The command that the attacker wants to send to the infected machine is first checked for special and numeric characters and replaced with ascii characters, since most Spotify songs don't start with a special character or a number. The replacement method I used was fairly simple: SPACE character was 'space', / was 'fslash', \ was 'bslash' and so on. Once the command is written in all ascii characters, an acrostic is generated based of a list of Spotify songs organized by genre (credit to [Acrostify](https://github.com/plamere/enspex/tree/master/web/Acrostify) for the database of songs). Using my PoC, you can select which genre of music to generate the acrostic from, cause why not :). 

The acrostic generated is also randomized, so repeating characters will not have repeating songs. Once the acrostic is generated, a playlist is created with a name of your choice. For my PoC, the name of the playlist does not matter, but it could be used to organize commands, or even correspond to times at which the command should be run on the infected machine (might add that feature later). The playlist will contain all the songs from the acrostic. However, an issue I ran into was certain genres of the song database wouldn't generate the exact acrostic correctly, occasionally adding or replacing characters that shouldn't be there. I didn't test this on all genres (jazz and country were the ones I noticed the issue with), but the rock genre never gave me any issues, so I'd reccommend that until I figure out what the issue is.

Below shows a playlist created from the command "cat /etc/passwd". You can see the beginning of the command hidden in the acrostic:

![](/assets/2019-12-22-SpotifyC2/1.png)

Once the playlist is created, the playlist ID and command is placed in a file (playlist_id_list.txt) on your local machine, which is to be used later when retrieving the output from the infected machine.

In my PoC, the script that does all this is [genAcrostic.py](https://github.com/JohnWoodman/SpotifyC2/blob/master/genAcrostic.py)

### [](#header-4)The Backdoor

This part describes everything that the infected machine is doing to receive and execute the command as well as send back the command output. The backdoor beacons out periodically (the less freqeunt, the more stealhty), making a request to the Spotify API to list all of its current playlists. Each playlist contains a command, hidden in an acrostic built from the songs in the playlist. The backdoor gets the first letter of each song, decodes the special characters and numbers as needed, and formulates a command to be executed. 

Initially, I was going to have the output of the command encoded in an acrostic just as I did when sending the command, but I realized that there were a lot more special characters and keys, which would make the acrostic overly and unnecessarily complex. While looking through the Spotify app to see if there were any other ways, I noticed that each playlist has a description box. I decided that it made much more sense to send the base64 encoded output through there. 

However, the description box has a size limit of 300 characters, too short for the majority of the base64 encoded output. A fix I came up with was to split the base64 encoded output into 300 character pieces, placing the first piece in the description of the original command's playlist. The subsequent 300 character pieces are then placed into newly created playlists until the entire output is used. In order for the attacker machine to re-assemble the base64 encoded output, the name of each of the newly created playlists are based off the playlist ID of original command's playlist, with an incrementing number added to the end.

Below shows a playlist created by the backdoor. A piece of the base64 encoded output is embedded in the description, and the name of the playlist reflects the playlist ID of the original command acrsotic, with an incrementing number added as the suffix (the image shows the 29th playlist created for this output). On the left are the list of the other playlists created, each containing a piece of the output to be re-assembled and decoded:

![](/assets/2019-12-22-SpotifyC2/2.png)

In my Poc, the script that does all this is [backdoor.py](https://github.com/JohnWoodman/SpotifyC2/blob/master/backdoor.py)
 
### [](#header-5)Retrieving Output

Retrieving the output from the command is fairly straight forward. A request is made to the Spotify API to retrieve a list of all the playlists, which now contain the newly created ones from the backdoor. The description is retrieved from each of the playlists, and based off the incrementing number at the end of each playlist ID, the base64 encoded text is re-assembled in the proper order, and is then decoded to output of the command. Since multiple commands can be sent to the backdoor, in order to correspond an output to a specific command, the file "playlist_id_list.txt" is used to relate a playlist ID with its command. Once all the command outputs are retrieved and decoded, the "playlist_id_list.txt" file is deleted, as well as the Spotify playlists themselves.

As shown below, once this process is complete, the playlists associated with the command and its output is deleted:

![](/assets/2019-12-22-SpotifyC2/3.png)

In my PoC, the script that does all this is [getOutput.py](https://github.com/JohnWoodman/SpotifyC2/blob/master/getOutput.py)

## [](#header-6)Conclusion

This method of Command and Control actually works quite well compared with other forms of social media C2. Commands are hidden in a unique way that may not be easily detected, and considering the vast number of playlists existing in Spotify, finding the C2 playlists would be quite a challenge for anyone looking for them. Some drawbacks to this method is the fact that Spotify never actually deletes a playlist, it technically only unfollows it. This isn't a huge issue, as finding the playlist after unfollowing it is extremely difficult, but it should be known that it isn't impossible. I suppose the main drawback is the fact that it probably makes more sense to use the other methods of C2 as they are likely more reliable and more private, such as gmail or Direct Messaging in other social media platforms. However, SpotifyC2 provides its own fun and unique ways of keeping commands hidden. 

I started this project firstly to learn more about Command and Control and the various methods used, and secondly to prove that this method could be done and that Spotify is a viable option for Command and Control, and I think I've done just that. While it isn't the most practical, it certainly holds its own amongst the other unique methods of C2. Not to mention, its a lot of fun to think you can control someone's computer by sending We Will Rock You.
  


