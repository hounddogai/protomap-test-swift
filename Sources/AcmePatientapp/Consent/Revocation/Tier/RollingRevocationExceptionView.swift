import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling revocation exception.
    final class RollingRevocationExceptionView {
        var codeText: String
        var label: String
        var locale: String
        var windowDaysText: String
        var archived: String
        var amount: String
        var score: String
        var contactEmail: String
        var visibleText: String
        var statusLabel: String

        init(codeText: String, label: String, locale: String, windowDaysText: String, archived: String, amount: String, score: String, contactEmail: String, visibleText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.locale = locale
            self.windowDaysText = windowDaysText
            self.archived = archived
            self.amount = amount
            self.score = score
            self.contactEmail = contactEmail
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRevocationExceptionView(_ item: RollingRevocationException) -> RollingRevocationExceptionView {
        return RollingRevocationExceptionView(
            codeText: item.code,
            label: item.label,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            windowDaysText: String(item.windowDays),
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            score: String(format: "%.2f", item.score),
            contactEmail: item.contactEmail,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRevocationExceptionViews(_ items: [RollingRevocationException]) -> [RollingRevocationExceptionView] {
        var views: [RollingRevocationExceptionView] = []
        for item in items {
            views.append(toRollingRevocationExceptionView(item))
        }
        return views
    }

    static func sumRollingRevocationExceptionView(_ view: RollingRevocationExceptionView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedWindowDays) + parsedAmount + parsedScore
    }
}
