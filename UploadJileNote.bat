git init
git config --global user.name "jilefo"
git config --global user.email "jilefo@outlook.com"
git remote add gitee git@gitee.com:jilefo/AlistPlus.git
rem git pull --rebase origin master
rem git pull --rebase github master
git add .
rem git branch --set-upstream-to origin/master
rem git rebase --continue
git commit -m "Auto commit."
rem git push -u origin master
rem git push -u github master
git pull origin master
git push origin master
git push -f origin master