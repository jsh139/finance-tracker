class User < ApplicationRecord
  has_many :user_stocks
  has_many :stocks, through: :user_stocks
  has_many :friendships
  has_many :friends, through: :friendships
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def under_stock_limit?
    stocks.count < 10
  end

  def stock_already_tracked?(ticker_symbol)
    stock = Stock.check_db(ticker_symbol)
    return false unless stock

    stocks.where(id: stock.id).exists?
  end

  def can_track_stock?(ticker_symbol)
    under_stock_limit? && !stock_already_tracked?(ticker_symbol)
  end

  def full_name
    return "#{first_name} #{last_name}" if first_name || last_name

    'Anonymous'
  end

  def self.search(search_string)
    search_string.strip!

    to_return = (find_friends_by_first_name(search_string) +
                find_friends_by_last_name(search_string) +
                find_friends_by_email(search_string)).uniq

    return nil unless to_return

    to_return
  end

  def self.matches(field_name, search_string)
    where("#{field_name} like ?", "%#{search_string}%")
  end

  def self.find_friends_by_first_name(search_string)
    matches('first_name', search_string)
  end

  def self.find_friends_by_last_name(search_string)
    matches('last_name', search_string)
  end

  def self.find_friends_by_email(search_string)
    matches('email', search_string)
  end

  def except_current_user(users)
    users.reject { |user| user.id == self.id }
  end

  def user_is_following_friend?(friend_id)
    friends.where(id: friend_id).exists?
  end
end
