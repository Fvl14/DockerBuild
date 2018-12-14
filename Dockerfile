######################################################################
FROM centos:latest

MAINTAINER Vasyl Frankiv <frankiv14@gmail.com>

######################################################################
# PERL - this one should be install first
RUN yum install -y curl make bzip2 cpio file gcc \
    && mkdir /usr/src/perl \
    && cd /usr/src/perl \
    && curl -SL https://cpan.metacpan.org/authors/id/S/SH/SHAY/perl-5.24.4.tar.bz2 -o perl-5.24.4.tar.bz2 \
    && tar --strip-components=1 -xjf perl-5.24.4.tar.bz2 -C /usr/src/perl \
    && rm perl-5.24.4.tar.bz2 \
    && ./Configure -Duse64bitall -Dusethreads -Duseshrplib  -des \
    && make -j$(nproc) \
    && TEST_JOBS=$(nproc) make test_harness \
    && make install \
    && make veryclean

RUN cd /usr/src \
    && curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
    && chmod +x cpanm \
    && ./cpanm App::cpanminus \
    && rm ./cpanm

######################################################################
# Install a basic #perl-ExtUtils-MakeMaker
RUN yum install -y openssh-server unzip lsof java-1.8.0-openjdk-headless \
    bzip2 ca-certificates cpio dpkg-dev g++ libbz2-dev libdb-dev \
    libc6-dev libgdbm-dev liblzma-dev netbase patch procps zlib1g-dev xz-utils \
    wget python cifs-utils expat-devel openssl-devel libtool zlib-devel openssl \
    curl-devel gettext-devel samba-client samba-common rsync \
    \ && yum clean all
######################################################################
# PERL MODULES
RUN cpan --force File::Copy FileHandle

RUN cpanm --force Array::Compare \
        Capture::Tiny \
        Cwd \
        Data::Dumper \
        Devel::Cover \
        Devel::StackTrace \
        Encode \
        Env \
        Fcntl \
        File::Basename \
      #  File::Copy \ 
        File::Find \
        File::Find::Rule \
        File::Path \
        File::Spec \
        File::Touch \
      #  FileHandle \
        Filesys::DfPortable \
      #  Filesys::DiskUsage \
        FindBin \
        IO::CaptureOutput \
        Jenkins::API \
        JSON \
        JSON::Parse \
        Log::Log4perl \
        LWP::Simple \
        Moo \
        MooX \
        MooX::late \
        MooX::Types::MooseLike \
        Net::GitHub::V3 \
        Net::GitHub::V4 \
        Proc::Background \
        Readonly \
        Term::ReadKey \
        Test::Class \
        Test::Exit \
        Test::Mock::Cmd \
        Test::MockModule \
        Throwable \
        TryCatch \
        Unicode::Escape \
        XML::DOM \
        MooX::Override \
        Ukigumo::Client \
        Devel::Cover \
        File::Touch \
        YAML::XS \
        Tie::IxHash \
        XML::Hash \
        DateTime::Format::Strptime \
        Data::Alias \
      #  W3C::SOAP \
      #  W3C::SOAP::WSDL \
        Test::Moose::MockObjectCompile \
        Net::Graphite \
        Data::Compare \
        MooX::Singleton \
        REST::Client \
        Hash::Ordered
######################################################################
# GIT
RUN yum remove git -y \
    && yum install -y perl-ExtUtils-MakeMaker \
    && cd /usr/src \
    && wget https://www.kernel.org/pub/software/scm/git/git-2.3.4.tar.gz \
    && tar xzf git-2.3.4.tar.gz \
    && cd git-2.3.4 \
    && make prefix=/usr/local/git all \
    && make prefix=/usr/local/git install \
    && echo 'export PATH=$PATH:/usr/local/git/bin' >> /etc/bashrc \
    && source /etc/bashrc \
    && export PATH=/usr/local/git/bin:$PATH \
    && git --version 
######################################################################
# JENKINS
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd \
    && mkdir -p /var/run/sshd \
    && useradd -u 1000 -m -s /bin/bash jenkins \
    && echo "jenkins:jenkins" | chpasswd \
    && /usr/bin/ssh-keygen -A \
    && echo export JAVA_HOME="/`alternatives  --display java | grep best | cut -d "/" -f 2-6`" >> /etc/environment

# Set java environment
ENV JAVA_HOME /etc/alternatives/jre
######################################################################
# RAR
RUN cd /var/tmp \
    && wget https://forensics.cert.org/centos/cert/7/x86_64//rar-5.3.0-1.el7.x86_64.rpm \
    && rpm -ihv rar-5.3.0-1.el7.x86_64.rpm \
    && rar

######################################################################
# SENDEMAIL
RUN cd /var/tmp \
    && wget http://caspian.dotconf.net/menu/Software/SendEmail/sendEmail-v1.56.tar.gz \
    && tar -xvf sendEmail-v1.56.tar.gz \
    && cp -a sendEmail-v1.56/sendEmail /usr/local/bin \
    && chmod +x /usr/local/bin/sendEmail
    # && sed -i 's/if \(! IO::Socket::SSL->start_SSL\(\$SERVER, SSL_version => \'TLSv1\'/! IO::Socket::SSL->start_SSL\(\$SERVER, SSL_version => \'TLSv1\', SSL_verify_mode => 0/' /usr/local/bin/sendEmail \
    # && sendEmail

######################################################################
# RUBY 
RUN yum install -y ruby-2.2.5 \
    && gem install cucumber -v 2.3.3 \
    && gem install rspec -v 3.4.0 \
    && gem install systemu -v 2.6.5 \ 
    && gem install git -v 1.3 \ 
    && gem install octokit -v 4.0 \
    && gem install simple-graphite  -v 2.1.0 

######################################################################
# OTHERS
RUN chmod 777 /mnt

######################################################################
# Standard SSH port
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"] 
