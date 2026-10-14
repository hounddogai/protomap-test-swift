import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim threshold.
    final class ClaimThresholdView {
        var codeText: String
        var title: String
        var patientRefText: String
        var category: String
        var archivedText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, title: String, patientRefText: String, category: String, archivedText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRefText = patientRefText
            self.category = category
            self.archivedText = archivedText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toClaimThresholdView(_ item: ClaimThreshold) -> ClaimThresholdView {
        return ClaimThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            patientRefText: item.patientRef,
            category: Kit.Text.truncate(item.category, limit: 64),
            archivedText: "\(item.archived)",
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimThresholdViews(_ items: [ClaimThreshold]) -> [ClaimThresholdView] {
        var views: [ClaimThresholdView] = []
        for item in items {
            views.append(toClaimThresholdView(item))
        }
        return views
    }

    static func sumClaimThresholdView(_ view: ClaimThresholdView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
