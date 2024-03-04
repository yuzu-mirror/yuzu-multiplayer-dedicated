# yuzu Multiplayer Dedicated Lobby

Quickly stand up new dedicated multiplayer lobbies that will be broadcasted on yuzu.

## Usage
```
sudo docker run -d \
  --publish 5000:5000/udp \
  yuzuemu/yuzu-multiplayer-dedicated \
  --room-name "(COUNTRY) (REGION) - GAME TITLE" \
  --preferred-game "GAME TITLE" \
  --preferred-game-id "TITLE ID" \
  --port 5000 \
  --max_members 4 \
  --token "YUZU ACCOUNT TOKEN" \
  --enable-yuzu-mods \
  --web-api-url https://api.yuzu-emu.org
```

**Please note, the token format has changed as of 11/1/2019.**

**You can retrieve your token from https://profile.yuzu-emu.org/**

Room name should follow the below format.
If multiple servers are stood up, `Server 1`, `Server 2` format should be used.
```
USA East - Super Smash Bros. Ultimate - Server 1
USA East - Super Smash Bros. Ultimate - Server 2
USA East - Mario Kart 8 Deluxe - Server 1
USA East - Mario Kart 8 Deluxe - Server 2
USA East - Splatoon 2 - Server 1
USA East - Splatoon 2 - Server 2
USA East - Pokémon Sword and Shield - Server 1
USA East - Pokémon Sword and Shield - Server 2
USA East - Animal Crossing: New Horizons - Server 1
USA East - Animal Crossing: New Horizons - Server 2
USA East - Pokémon Legends: Arceus
USA East - Pokémon: Let’s Go
USA East - Puyo Puyo Tetris
USA East - Super Mario 3D World + Bowser's Fury
USA East - Super Mario Party
USA East - MONSTER HUNTER RISE
```
