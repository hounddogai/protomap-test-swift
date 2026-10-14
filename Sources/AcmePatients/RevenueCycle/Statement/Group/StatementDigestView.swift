import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement digest.
    final class StatementDigestView {
        var code: String
        var labelText: String
        var startsAt: String
        var phone: String
        var payerText: String
        var version: String
        var statusLabel: String

        init(code: String, labelText: String, startsAt: String, phone: String, payerText: String, version: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.startsAt = startsAt
            self.phone = phone
            self.payerText = payerText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toStatementDigestView(_ item: StatementDigest) -> StatementDigestView {
        return StatementDigestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            startsAt: String(item.startsAt),
            phone: item.phone,
            payerText: item.payer,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementDigestViews(_ items: [StatementDigest]) -> [StatementDigestView] {
        var views: [StatementDigestView] = []
        for item in items {
            views.append(toStatementDigestView(item))
        }
        return views
    }

    static func sumStatementDigestView(_ view: StatementDigestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVersion)
    }
}
