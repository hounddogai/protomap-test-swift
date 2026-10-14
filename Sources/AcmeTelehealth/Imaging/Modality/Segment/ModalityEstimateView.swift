import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality estimate.
    final class ModalityEstimateView {
        var code: String
        var label: String
        var weight: String
        var ward: String
        var description: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, weight: String, ward: String, description: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.ward = ward
            self.description = description
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toModalityEstimateView(_ item: ModalityEstimate) -> ModalityEstimateView {
        return ModalityEstimateView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            weight: String(format: "%.2f", item.weight),
            ward: item.ward,
            description: item.description,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityEstimateViews(_ items: [ModalityEstimate]) -> [ModalityEstimateView] {
        var views: [ModalityEstimateView] = []
        for item in items {
            views.append(toModalityEstimateView(item))
        }
        return views
    }

    static func sumModalityEstimateView(_ view: ModalityEstimateView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
