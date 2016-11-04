class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  has_many :knockee_meetings, :class_name => 'Meeting', :foreign_key => 'knockee_id'
  has_many :knocker_meetings, :class_name => 'Meeting', :foreign_key => 'knocker_id'

  has_many :knockee_transactions, :class_name => 'Transaction', :foreign_key => 'knockee_id'
  has_many :knocker_transactions, :class_name => 'Transaction', :foreign_key => 'knocker_id'
end
