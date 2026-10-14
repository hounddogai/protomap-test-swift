import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling substitution digest.
    final class RollingSubstitutionDigestView {
        var codeText: String
        var labelText: String
        var timezone: String
        var ward: String
        var pinned: String
        var visible: String
        var payer: String
        var amount: String
        var statusLabel: String

        init(codeText: String, labelText: String, timezone: String, ward: String, pinned: String, visible: String, payer: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.timezone = timezone
            self.ward = ward
            self.pinned = pinned
            self.visible = visible
            self.payer = payer
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSubstitutionDigestView(_ item: RollingSubstitutionDigest) -> RollingSubstitutionDigestView {
        return RollingSubstitutionDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            timezone: item.timezone,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            pinned: "\(item.pinned)",
            visible: "\(item.visible)",
            payer: Kit.Text.truncate(item.payer, limit: 64),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSubstitutionDigestViews(_ items: [RollingSubstitutionDigest]) -> [RollingSubstitutionDigestView] {
        var views: [RollingSubstitutionDigestView] = []
        for item in items {
            views.append(toRollingSubstitutionDigestView(item))
        }
        return views
    }

    static func sumRollingSubstitutionDigestView(_ view: RollingSubstitutionDigestView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
