import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim template.
    final class ClaimTemplateView {
        var code: String
        var label: String
        var ward: String
        var quantity: String
        var visible: String
        var revisionText: String
        var maximum: String
        var endsAt: String
        var region: String
        var statusLabel: String

        init(code: String, label: String, ward: String, quantity: String, visible: String, revisionText: String, maximum: String, endsAt: String, region: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ward = ward
            self.quantity = quantity
            self.visible = visible
            self.revisionText = revisionText
            self.maximum = maximum
            self.endsAt = endsAt
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toClaimTemplateView(_ item: ClaimTemplate) -> ClaimTemplateView {
        return ClaimTemplateView(
            code: item.code,
            label: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 40),
            quantity: String(item.quantity),
            visible: "\(item.visible)",
            revisionText: String(item.revision),
            maximum: String(format: "%.2f", item.maximum),
            endsAt: String(item.endsAt),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimTemplateViews(_ items: [ClaimTemplate]) -> [ClaimTemplateView] {
        var views: [ClaimTemplateView] = []
        for item in items {
            views.append(toClaimTemplateView(item))
        }
        return views
    }

    static func sumClaimTemplateView(_ view: ClaimTemplateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRevision) + parsedMaximum
    }
}
