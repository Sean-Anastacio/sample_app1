class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  
  def User.new_token #記憶トークンを生成する
    SecureRandom.urlsafe_base64
  end
  
  #永続化セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token #記憶トークンを生成する
    update_attribute(:remember_digest, User.digest(remember_token)) #記憶トークンをハッシュ化したのち、テーブルのremember_digestを変更する
    remember_digest
  end
  
  def session_token
    remember_digest || remember
  end
  
  #渡されたトークンがダイジェストと一致したらtrueを返す
  #メタプログラミング、sendを使ってさまざまなdigestに対して対応できるようにした。
  def authenticated?(attribute,token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end
  #remember_tokenはローカル変数であり、一方でremember_digestはdbのカラムに対応しているのでActive Recordで簡単に取得・保存できる。→O/Rマッピング、オブジェクトリレーショナルマッピング
  #self.nameをname,self.emailをemailとして取り出せたのと同じ
  #User < ApplicationRecord < ActiveRecord::Base < Object
  
  
  def forget
    update_attribute(:remember_digest, nil)
  end
  
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end
  
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end
  
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
  
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  
  private
  
      #メールアドレスをすべて小文字にする
      def downcase_email
        email.downcase!
      end
      
      #有効化トークンとダイジェストを作成及び代入する
      def create_activation_digest
        self.activation_token = User.new_token
        self.activation_digest = User.digest(activation_token)
      end
      
      
end
