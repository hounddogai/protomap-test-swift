import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality claim.
    final class ModalityClaimView {
        var code: String
        var label: String
        var externalRef: String
        var allergy: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, externalRef: String, allergy: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.allergy = allergy
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toModalityClaimView(_ item: ModalityClaim) -> ModalityClaimView {
        return ModalityClaimView(
            code: item.code,
            label: item.label,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            allergy: item.allergy,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityClaimViews(_ items: [ModalityClaim]) -> [ModalityClaimView] {
        var views: [ModalityClaimView] = []
        for item in items {
            views.append(toModalityClaimView(item))
        }
        return views
    }

    static func sumModalityClaimView(_ view: ModalityClaimView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
