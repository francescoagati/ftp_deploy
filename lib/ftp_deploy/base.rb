require 'net/ftp'

module FtpDeploy
  
  class Base
    
    def initialize(cfg = nil, &block)
      @logger=[]
      cfg.each_pair{ |k,v| config[k] = v } unless cfg.nil?
      self.instance_eval &block if block_given?
    end
    
    def log(msg)
      @logger << msg
    end
    
    def get_log
      @logger.join("\n")
    end
    
    
    def config(&block)
      @config ||= Configuration.new do
        set :port, 21
        set :base_dir, './'
        set :verbose, true
        set :passive, true
      end
      
      if block_given?
        @config.instance_eval &block
      end
      
      @config
    end
    
    def connect!
      @ftp ||= Net::FTP.open(config[:host], config[:user], config[:password])
      @ftp.passive = config[:passive]
      if block_given?
        yield self
        @ftp.close
      end
      @ftp
    end
    
    def upload_release!
      #remove_all_below(remote_base_dir)
      
      #release = Time.new.strftime "%Y-%d-%m_%H-%M-%S"
      #release_dir = File.join(remote_base_dir, release)
      
      #@ftp.mkdir release_dir
      
      Dir.glob("#{local_base_dir}/**/**").sort.each do |el|
        upload el, remote_base_dir
      end
      
      #htaccess_file = File.join(local_base_dir, '.htaccess')
      #open(htaccess_file, 'w') do |f|
      #  f << "Options +FollowSymLinks
      #        RewriteEngine On
      #        RewriteCond %{ENV:REDIRECT_STATUS} ^$
      #        RewriteRule .* #{release_dir}%{REQUEST_URI} [QSA,L]"
      #end
        
      #upload(htaccess_file, remote_base_dir)
    end
    
    def remove_all_below dir
      @ftp.chdir(dir)
      dircontent = @ftp.list('-A1')
      dircontent.each do |file|
        filepath = File.join(dir, file)
        begin
          remove_all_below filepath
          log "deleting #{filepath}" if config[:verbose]
          @ftp.rmdir filepath
        rescue
          log "deleting '#{filepath}'" if config[:verbose]
          @ftp.delete filepath
        end
      end
    end
    
    def upload element, release_dir
      local_element = element
      remote_element = element.gsub(local_base_dir, release_dir)
      
      log "Uploading file '#{local_element}' to '#{remote_element}'" if config[:verbose]
      
      if FileTest.directory?(local_element)
        begin
          @ftp.mkdir(remote_element) 
        rescue Exception => e
          log "error create folder but ok go on!"
        end
        
      else
        @ftp.put element, remote_element
      end
    end
    
    def local_base_dir
      File.expand_path(@config[:base_dir])
    end
    
    def remote_base_dir
      if @remote_base_dir.nil?
        @ftp.chdir(config[:remote_base_dir]) unless config[:remote_base_dir].nil?
        @remote_base_dir = @ftp.pwd
      end
      @remote_base_dir
    end
  end
end