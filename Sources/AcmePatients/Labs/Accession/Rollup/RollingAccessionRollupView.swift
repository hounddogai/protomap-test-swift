import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession rollup.
    final class RollingAccessionRollupView {
        var codeText: String
        var name: String
        var externalRef: String
        var visibleText: String
        var active: String
        var contactEmail: String
        var amount: String
        var statusLabel: String

        init(codeText: String, name: String, externalRef: String, visibleText: String, active: String, contactEmail: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.externalRef = externalRef
            self.visibleText = visibleText
            self.active = active
            self.contactEmail = contactEmail
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionRollupView(_ item: RollingAccessionRollup) -> RollingAccessionRollupView {
        return RollingAccessionRollupView(
            codeText: item.code,
            name: item.name,
            externalRef: item.externalRef,
            visibleText: "\(item.visible)",
            active: "\(item.active)",
            contactEmail: item.contactEmail,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionRollupViews(_ items: [RollingAccessionRollup]) -> [RollingAccessionRollupView] {
        var views: [RollingAccessionRollupView] = []
        for item in items {
            views.append(toRollingAccessionRollupView(item))
        }
        return views
    }

    static func sumRollingAccessionRollupView(_ view: RollingAccessionRollupView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
