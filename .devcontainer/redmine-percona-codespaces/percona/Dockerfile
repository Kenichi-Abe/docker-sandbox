# Percona Server 5.7
# 公式 percona:5.7 をベースに、Redmine 向けの文字コード設定だけ焼き込む
FROM percona:5.7

# 公式 percona:5.7 は CentOS 系で /etc/my.cnf.d を使う。
# パスが違う派生イメージでも効くよう両方に置く。
COPY conf.d/redmine.cnf /etc/my.cnf.d/redmine.cnf
COPY conf.d/redmine.cnf /etc/mysql/conf.d/redmine.cnf

EXPOSE 3306
