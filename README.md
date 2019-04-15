# MT5-MT4-Telegram-API-Bot
MT5-MT4-Telegram-API-Bot is a Bot that communicates with Telegram, and copy all trades from one MT4 or MT5 terminal to Telegram Groups or channel - It support MQL4/MQL5 language.
it delivers Trade Signal Alert From MT4 and MT5 Terminal to Telegram, EMail, or the notification terminal


# TODO
* Search for a bot on telegram with name "@BotFather". We will find it through the search engine. After adding it to the list of contacts,
we will start communicating with it using the /start command. As a response it will send you a list of all available commands, As shown in the image below
![pic1](https://user-images.githubusercontent.com/32399318/56162967-1fe7ed00-5fc5-11e9-9555-192c33b34d7f.jpg)


* With the /newbot command we begin the registration of a new bot. We need to come up with two names. The first one is a name of a bot that 
can be set in your native language. The second one is a username of a bot in Latin that ends with a “bot” prefix. As a result, we obtain 
a token or API Key – the access key for operating with a bot through API as shown below

![pic2](https://user-images.githubusercontent.com/32399318/56163370-0d21e800-5fc6-11e9-8481-69861daa4a1e.jpg)

## Operation mode for bots

With regard to bots, you can let them join groups by using the /setjoingroups command. If a bot is added to a group, then by using the /setprivacy command you can set the option to either receive all messages, or only those that start with a sign of the symbol team “/”. 

![pic4](https://user-images.githubusercontent.com/32399318/56163746-05af0e80-5fc7-11e9-801c-362d94e36a4d.jpg)

The other mode focuses on operation on a channel. Telegram channels are accounts for transmitting messages for a wide audience that support an unlimited number of subscribers. The important feature of channels is that users can't leave comments and likes on the news feed (one-way connection). Only channel administrators can create messages there 

![pic5__2](https://user-images.githubusercontent.com/32399318/56163931-8241ed00-5fc7-11e9-99e4-96a879ae0b9a.jpg)


* Export and copy all files from include to the MT4/MT5 include folder, input the api key from the bot to the Expert Advisor's token, add the bot as an administrator of your signal channel or Group, any event that happens on your trade terminal will be notify to instantly on your channel


![telegram](https://user-images.githubusercontent.com/32399318/56165502-0ba6ee80-5fcb-11e9-8332-7a09860f61b5.jpg)

![test1](https://user-images.githubusercontent.com/32399318/56165638-63ddf080-5fcb-11e9-9b88-5e9fb94821b6.jpg)










