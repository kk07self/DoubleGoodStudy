#  git 高频率使用命令

#### 1、git 配置

在 Git 中，我们一般只需要关注两个配置文件，`gitconfig` 和 `.gitignore`，前者用来对 git 的行为进行配置，后者则用来指定文件的忽略规则。如果命中了规则，就不会添加到 Git 的版本管理中。

对于某个 Git 仓库来说，一般同时有两个 `gitconfig` 文件生效，一个是 `~/.gitconfig`，它是全局的配置，另一个则位于每个 git 仓库下的 `.git/config`。如果有重复的配置项，项目配置的优先级高于全局配置，否则两者是相辅相成的关系。

`.gitignore` 文件也是类似，分为全局和项目两个配置，区别在于在 git 仓库中的任意一个目录都可以有 `.gitignore` 文件，当然这个文件只对此目录内的文件生效。具体配置请看第6点



#### 2、查看提交记录

- **git log**：可以查看过去提交的记录，只敲```git log```是换行显示，可以同行显示一条提交的记录，```git lg```这是本人自己配置的命令，全命令是```git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue) <%an>%Creset' --abbrev-commit``` 。可以在.gitconfig中配置剪短命令：

  ```bash
  [alias]
      lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ci) %C(bold blue) <%an>%Creset' --abbrev-commit
  ```

- **git lg --stat**：查看记录的详细信息，即在上一个命令后面加上参数```--stat```

- **git lg -p**：查看具体改动的内容，```git lg -p -n```只查看前n个提交记录

- **git lg -p grep message**：只显示提交记录里包含**message**的记录

- **git lg -p file_name**：只显示指定文件的提交改动历史

- **git diff**：可查看工作区内的变动，即当前修改的变动

- **git diff --staged**：可查看暂缓区内的变动，即被```git add```了的文件变动

- **git diff HEAD^ HEAD**：查看最近一次提交的变动

- **git grep --break --heading -n message**：查看包含message的文件及所在的行数，可以进行简短配置```git g messge```来等同此效果。然后输入```git lg -p -L 25,25:./git.md```，即查找文件**git.md**中第25行的提交历史

- **git diff branch_a..branch_b 或 git diff branch_a branch_b**：两个分支之间提交的差异

- **git diff branch_a...branch_b**：查看在b上提交但没在a上提交的记录

- **git lg branch_a..branch_b**：等同于```git diff branch_a...branch_b```

- **git lg branch_a...branch_b**：查看只在a上提交的和只在b上提交的，即查看各分支的一次提交

 

#### 3、分支与tag

- **创建分支**：

  - **git branch branch_name**：创建一个新的分支

  - **git branch branch_name commit**：创建一个分支并指向摸个提交

  - **git checkout -b branch_name**：创建一个分支，并切换到这个分支上

  - **git branch -t branch_name origin/branch_name**：创建一个分支，并同步远程，但不会切换到新的分支

  - **git branch -t branch_name origin/branch_name**：创建一个分支，并同步远程，并且会切换到新的分支

  - **git branch --track origin/branch_name**：创建一个分支，并同步远程，并且会切换到新的分支

- **查看分支**：

  - **git branch**：查看本地所有分支

  - **git branch -vv**：查看本地所有分支及最近一次的提交记录及当前分支跟踪的远程分支

  - **git branch -a**：查看本地分支喝远程分支

  - **git branch -remote**：查看远程分支

- **删除分支**：

  - **git branch -d branch_name**：删除某个分支

  - **git branch -D branch_name**：强行删除某个分支

- **切换分支**：

  - **git checkout branch_name**：切换分支

  - **git checkout -b branch_name**：创建并切换到分支

- **tag**

  标签是分支功能的子集，可以理解为不能移动的分支。前文说过，分支始终指向某个链表的开端，是可以移动的。但 Tag 始终指向某个固定的提交，不会移动。

  - **git tag tag_name**：打个标签

  - **git tag -d tag_name**：删除标签



#### 4、代码同步与修改

**工作区**、**暂缓区**、**历史区**

```git status```：会显示需要暂缓的文件

```git add```：将**工作区**的修改同步到**暂缓区**

```git commit```：将```暂缓区```的同步到```历史区```

- **远程代码拉取**

  - **git clone 远程地址仓库**：将远程代码clone到本地

  - **git pull**：拉取远程仓库的代码同步到本地，覆盖本地的修改，等同于```fetch```+```merge```，谨慎使用

  - **git down**：拉取远程代码遍基到本地，是```git stash;git fetch;git rebase;git stash pop;```的缩写

- **代码提交**：

  - **git add**：会把改动的文件和要提交的部分拷贝到暂存区中，此时工作区和暂存区是一致的

  - **git add.**：功能同上，但是全部提交

  - **git commit**：将暂缓区的修改同步到历史区

  - **git commit -a -m"说明"**：同步到历史区并做提交说明

  - **git commit --all -m"说明"**：等同于```git add.```+```git commit -m```

  - **git stash**：存储改动

  - **git stash pop**：复原存储，同上一步相反的功能

- **代码撤销**

  - **git reset --soft SHA-1**：让历史区与制定的某次提交保持一致

  - **git reset --mixed SHA-1**：让暂存区和历史区与指定的提交保持一致

  - **git reset --hard SHA-1**：让工作区、暂缓区、历史区与指定的提交保持一致，等于撤销了```git add``` 和```git commit``` 这是一个**不可挽回**的操作，请谨慎执行。

- **分支合并**

  假设当前所处在分支b上

  - **git rebase branch_a**：将分支a上的每一次提交依次遍基到b上，就是讲a提交历史记录插入到b的历史记录上
  - **git merge branch_a**：将分支a上的所有提交变成一次提交添加到b上


#### 5、解决冲突

冲突会被多个等号分割为两部分，上面是当前分支的改动，下面是将要合入得改动。

- **查看冲突**：

  - **git ls-files -u**：展示还未合并的改动

  - **git show :num:file_name**：查看指定的文件，会将文件的内容展示出来，这里的**num**和**file_name**是上面一行命令展示出来的还没有合并的改动

  - **git diff --ours**：以当前分支为准，将会以其他颜色展示出其他分支中冲突的部分

  - **git diff —others**：以其他分支为准，将会以其他颜色展示出当前分支冲突的部分

- **放弃合并**：

  - **git rebase --abort**：放弃rebase的合并

  - **git merge --abort**：放弃merge的合并

- **解决冲突**：

  - **git checkout --ours file_names**：以当前分支的改动为准，然后```git add file_names``` ```git commit```这里不用加-m参数，git会默认生产一个merge的message

  - **git checkout --others file_names**：刚好同上面相反



#### 6、忽略文件

首先，在你的工作区新建一个名称为`.gitignore`的文件。
然后，把要忽略的文件名填进去，Git就会自动忽略这些文件。

不需要从头写.gitignore文件，GitHub已经为我们准备了各种配置文件，只需要组合一下就可以使用了。所有配置文件可以直接在线浏览：[https://github.com/github/gitignore](https://link.jianshu.com/?t=https://github.com/github/gitignore) （共享万岁）

- **file_name.后缀**：忽略指定文件file_name
- ***.后缀**：忽略所有以此后缀的文件
- **dir/**：忽略指定文件夹
- ***ignore/**：忽略文件夹名末尾带**ignore**的所有文件夹
- ***** **ignore** ***/**：忽略文件夹名中间带**ignore**的所有文件夹

注意，这个文件仅对还没有被纳入 git 版本管理的文件生效，一旦某个文件被暂存过，再配置 `.gitignore` 就无效了，此时我们需要先把所有的文件取消暂存，再重新暂存。

我们可以配置命令 `reignore` 专门用于解决这类问题，它的完整定义如下：

```bash
alias reignore='git rm -r --cached . && git add .'
```