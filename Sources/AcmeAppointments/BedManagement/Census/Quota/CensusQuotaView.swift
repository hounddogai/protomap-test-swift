import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census quota.
    final class CensusQuotaView {
        var code: String
        var title: String
        var budgetText: String
        var countryText: String
        var timezone: String
        var attempts: String
        var windowDaysText: String
        var contactEmailText: String
        var startsAt: String
        var statusLabel: String

        init(code: String, title: String, budgetText: String, countryText: String, timezone: String, attempts: String, windowDaysText: String, contactEmailText: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budgetText = budgetText
            self.countryText = countryText
            self.timezone = timezone
            self.attempts = attempts
            self.windowDaysText = windowDaysText
            self.contactEmailText = contactEmailText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCensusQuotaView(_ item: CensusQuota) -> CensusQuotaView {
        return CensusQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            countryText: Kit.Text.truncate(item.country, limit: 40),
            timezone: item.timezone,
            attempts: String(item.attempts),
            windowDaysText: String(item.windowDays),
            contactEmailText: item.contactEmail,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusQuotaViews(_ items: [CensusQuota]) -> [CensusQuotaView] {
        var views: [CensusQuotaView] = []
        for item in items {
            views.append(toCensusQuotaView(item))
        }
        return views
    }

    static func sumCensusQuotaView(_ view: CensusQuotaView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedBudget + Double(parsedAttempts) + Double(parsedWindowDays)
    }
}
