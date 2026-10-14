import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict rounding estimate.
    final class StrictRoundingEstimateView {
        var codeText: String
        var nameText: String
        var active: String
        var label: String
        var externalRef: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, nameText: String, active: String, label: String, externalRef: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.active = active
            self.label = label
            self.externalRef = externalRef
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRoundingEstimateView(_ item: StrictRoundingEstimate) -> StrictRoundingEstimateView {
        return StrictRoundingEstimateView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            active: "\(item.active)",
            label: item.label,
            externalRef: item.externalRef,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRoundingEstimateViews(_ items: [StrictRoundingEstimate]) -> [StrictRoundingEstimateView] {
        var views: [StrictRoundingEstimateView] = []
        for item in items {
            views.append(toStrictRoundingEstimateView(item))
        }
        return views
    }

    static func sumStrictRoundingEstimateView(_ view: StrictRoundingEstimateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
