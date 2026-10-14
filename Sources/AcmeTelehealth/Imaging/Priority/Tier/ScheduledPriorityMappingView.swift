import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled priority mapping.
    final class ScheduledPriorityMappingView {
        var code: String
        var title: String
        var dosageMg: String
        var weight: String
        var allergyText: String
        var capacityText: String
        var expiresAt: String
        var threshold: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, dosageMg: String, weight: String, allergyText: String, capacityText: String, expiresAt: String, threshold: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.weight = weight
            self.allergyText = allergyText
            self.capacityText = capacityText
            self.expiresAt = expiresAt
            self.threshold = threshold
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPriorityMappingView(_ item: ScheduledPriorityMapping) -> ScheduledPriorityMappingView {
        return ScheduledPriorityMappingView(
            code: item.code,
            title: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            weight: String(format: "%.2f", item.weight),
            allergyText: item.allergy,
            capacityText: String(item.capacity),
            expiresAt: String(item.expiresAt),
            threshold: String(format: "%.2f", item.threshold),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPriorityMappingViews(_ items: [ScheduledPriorityMapping]) -> [ScheduledPriorityMappingView] {
        var views: [ScheduledPriorityMappingView] = []
        for item in items {
            views.append(toScheduledPriorityMappingView(item))
        }
        return views
    }

    static func sumScheduledPriorityMappingView(_ view: ScheduledPriorityMappingView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedDosageMg + parsedWeight + Double(parsedCapacity)
    }
}
