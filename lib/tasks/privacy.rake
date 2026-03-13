namespace :privacy do
  desc "Delete usage_logs older than 90 days (GDPR data retention)"
  task purge_usage_logs: :environment do
    cutoff = 90.days.ago
    count = UsageLog.where(created_at: ...cutoff).delete_all
    puts "Deleted #{count} usage_logs older than #{cutoff.to_date}"
  end

  desc "Delete expired sessions older than 90 days"
  task purge_old_sessions: :environment do
    cutoff = 90.days.ago
    count = Session.where(created_at: ...cutoff).delete_all
    puts "Deleted #{count} sessions older than #{cutoff.to_date}"
  end

  desc "Run all privacy data retention tasks"
  task purge_all: [:purge_usage_logs, :purge_old_sessions]
end
