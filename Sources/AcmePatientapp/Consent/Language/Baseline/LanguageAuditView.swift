import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language audit.
    final class LanguageAuditView {
        var code: String
        var name: String
        var unitText: String
        var approved: String
        var ownerID: String
        var attempts: String
        var graceDays: String
        var procedureCode: String
        var amount: String
        var currency: String
        var statusLabel: String

        init(code: String, name: String, unitText: String, approved: String, ownerID: String, attempts: String, graceDays: String, procedureCode: String, amount: String, currency: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unitText = unitText
            self.approved = approved
            self.ownerID = ownerID
            self.attempts = attempts
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.amount = amount
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageAuditView(_ item: LanguageAudit) -> LanguageAuditView {
        return LanguageAuditView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            approved: "\(item.approved)",
            ownerID: item.ownerID,
            attempts: String(item.attempts),
            graceDays: String(item.graceDays),
            procedureCode: item.procedureCode,
            amount: String(format: "%.2f", item.amount),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageAuditViews(_ items: [LanguageAudit]) -> [LanguageAuditView] {
        var views: [LanguageAuditView] = []
        for item in items {
            views.append(toLanguageAuditView(item))
        }
        return views
    }

    static func sumLanguageAuditView(_ view: LanguageAuditView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAttempts) + Double(parsedGraceDays) + parsedAmount
    }
}
