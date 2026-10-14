import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization ledger.
    final class AuthorizationLedgerView {
        var code: String
        var labelText: String
        var archivedText: String
        var categoryText: String
        var endsAtText: String
        var specialty: String
        var rateText: String
        var durationMinutesText: String
        var expiresAt: String
        var graceDays: String
        var statusLabel: String

        init(code: String, labelText: String, archivedText: String, categoryText: String, endsAtText: String, specialty: String, rateText: String, durationMinutesText: String, expiresAt: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archivedText = archivedText
            self.categoryText = categoryText
            self.endsAtText = endsAtText
            self.specialty = specialty
            self.rateText = rateText
            self.durationMinutesText = durationMinutesText
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationLedgerView(_ item: AuthorizationLedger) -> AuthorizationLedgerView {
        return AuthorizationLedgerView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            archivedText: "\(item.archived)",
            categoryText: item.category,
            endsAtText: String(item.endsAt),
            specialty: item.specialty,
            rateText: String(format: "%.2f", item.rate),
            durationMinutesText: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationLedgerViews(_ items: [AuthorizationLedger]) -> [AuthorizationLedgerView] {
        var views: [AuthorizationLedgerView] = []
        for item in items {
            views.append(toAuthorizationLedgerView(item))
        }
        return views
    }

    static func sumAuthorizationLedgerView(_ view: AuthorizationLedgerView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedEndsAt) + parsedRate + Double(parsedDurationMinutes)
    }
}
