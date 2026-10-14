import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional witness batch.
    final class RegionalWitnessBatchView {
        var codeText: String
        var labelText: String
        var updatedAt: String
        var minimum: String
        var batchSize: String
        var quantity: String
        var countryText: String
        var facilityText: String
        var priorityText: String
        var statusLabel: String

        init(codeText: String, labelText: String, updatedAt: String, minimum: String, batchSize: String, quantity: String, countryText: String, facilityText: String, priorityText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.updatedAt = updatedAt
            self.minimum = minimum
            self.batchSize = batchSize
            self.quantity = quantity
            self.countryText = countryText
            self.facilityText = facilityText
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalWitnessBatchView(_ item: RegionalWitnessBatch) -> RegionalWitnessBatchView {
        return RegionalWitnessBatchView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            updatedAt: String(item.updatedAt),
            minimum: String(format: "%.2f", item.minimum),
            batchSize: String(item.batchSize),
            quantity: String(item.quantity),
            countryText: item.country,
            facilityText: item.facility,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalWitnessBatchViews(_ items: [RegionalWitnessBatch]) -> [RegionalWitnessBatchView] {
        var views: [RegionalWitnessBatchView] = []
        for item in items {
            views.append(toRegionalWitnessBatchView(item))
        }
        return views
    }

    static func sumRegionalWitnessBatchView(_ view: RegionalWitnessBatchView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMinimum + Double(parsedBatchSize)
    }
}
