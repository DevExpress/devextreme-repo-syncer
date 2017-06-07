## Initial deploy

Use a Linux machine with Docker.

1. Create rootfs/root/.hgrc based on [.hgrc-sample](rootfs/root/.hgrc-sample)

2. Prepare a volume for repos

   ```
   docker volume create repos
   ```
   
    Volume structure:
    
    ```
    /var/lib/docker/volumes
    └─ repos
       └─ _data
          ├─ 17_1
          │  ├─ github
          │  └─ hg
          ├─ 17_2
          │  ├─ github
          │  └─ hg
          ├─ ...
          └─ branches.txt
    ```
    
    'github' dirs contain clones of [DevExpress/DevExtreme](https://github.com/DevExpress/DevExtreme)  
    'hg' dirs contain clones of https://hg.corp.devexpress.com/mobile  
    (no need to checkout specific branches, the script will do it)
    
    'branches.txt' - list of active branches, one per line

3. `build.sh`,  `start.sh`

4. `tail.sh`- check logs

## Add the next branch

- `docker stop syncer`
- Make a copy of clones:  
  `cp -r /var/lib/docker/volumes/repos/_data/XX_X /var/lib/docker/volumes/repos/_data/YY_Y`
- Add a line to branches.txt
- `docker start syncer`
- Check logs: `tail.sh`

## Exclude a branch
- Remove the line from 'branches.txt'
