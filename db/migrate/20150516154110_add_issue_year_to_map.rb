class AddIssueYearToMap < ActiveRecord::Migration
  def change
    add_column :maps, :issue_year, :integer
  end
end
