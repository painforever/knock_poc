class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates_format_of :cell_phone, with: Constants::VALID_PHONE_NUMBER_REGEX, message: "format is invalid.", if: "self.cell_phone.present?"

  #since 3 prices are all in same format, we validate them by same regex
  validates_each :phone_call_price, :meeting_price, :video_price do |record, attr, value|
    record.errors.add(attr, ' is invalid, price should be between 0 and 999.99, no dollar sign please.') if value.present? &&  !(value =~ Constants::VALID_US_CURRENCY)
  end

  # before_save do
  #   if self.student_status == 'college_student'
  #     self.student_status = 'georgetown log'
  #   else
  #     self.student_status = 'knocker logl'
  #   end
  # end

  #TODO I comment this just for now since we need to let user switch their roles when they signup
  #validates :highschool, presence: true

  ##Carrierwave Uploaders
  mount_uploader :avatar_path, AvatarUploader
  mount_uploader :resume_path, ResumeUploader
  mount_uploader :common_essay_path, CommonEssayUploader
  mount_uploader :college_essay_path, CollegeEssayUploader

  
  # Associations
  has_many :knockee_meetings, class_name: 'Meeting', foreign_key: 'knockee'
  has_many :knocker_meetings, class_name: 'Meeting', foreign_key: 'knocker'
  has_many :knockee_transactions, class_name: 'Transaction', foreign_key: 'knockee'
  has_many :knocker_transactions, class_name: 'Transaction', foreign_key: 'knocker'
  has_and_belongs_to_many :tags

  # Methods 
  
  def self.permitted(params)
    params.require(:user).permit!
  end

  def display_name
    "#{self.first_name} #{self.last_name}"
  end

  #TODO keep this, may need this later even if it's doing the same thing in carts controller.
  def pay_with_current_bank_or_create
    if self.stripe_customer_id.blank?
      customer = Stripe::Customer.create(
          card: token,
          description: "#{self.email}-#{self.display_name}",
          email: self.email
      )
      customer_id = customer.id
    else
      customer_id = self.stripe_customer_id
    end
    Stripe::Charge.create(
        amount: 500, # $15.00 this time
        currency: 'usd',
        customer: customer_id
    )
    # save the customer ID in your database so you can use it later
    current_user.update_column("stripe_customer_id", customer.id)
  end
end
