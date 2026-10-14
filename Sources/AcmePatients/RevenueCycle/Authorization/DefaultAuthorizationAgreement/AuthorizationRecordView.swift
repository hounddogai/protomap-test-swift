import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization record.
    final class AuthorizationRecordView {
        var code: String
        var nameText: String
        var attempts: String
        var patientRef: String
        var discount: String
        var cost: String
        var timezone: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, attempts: String, patientRef: String, discount: String, cost: String, timezone: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attempts = attempts
            self.patientRef = patientRef
            self.discount = discount
            self.cost = cost
            self.timezone = timezone
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationRecordView(_ item: AuthorizationRecord) -> AuthorizationRecordView {
        return AuthorizationRecordView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            attempts: String(item.attempts),
            patientRef: item.patientRef,
            discount: String(format: "%.2f", item.discount),
            cost: String(format: "%.2f", item.cost),
            timezone: item.timezone,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationRecordViews(_ items: [AuthorizationRecord]) -> [AuthorizationRecordView] {
        var views: [AuthorizationRecordView] = []
        for item in items {
            views.append(toAuthorizationRecordView(item))
        }
        return views
    }

    static func sumAuthorizationRecordView(_ view: AuthorizationRecordView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAttempts) + parsedDiscount + parsedCost
    }
}
