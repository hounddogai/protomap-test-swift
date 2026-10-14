import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read override.
    final class TieredReadOverrideView {
        var code: String
        var label: String
        var bed: String
        var encounterIDText: String
        var ratio: String
        var procedureCodeText: String
        var description: String
        var batchSize: String
        var priority: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, bed: String, encounterIDText: String, ratio: String, procedureCodeText: String, description: String, batchSize: String, priority: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.encounterIDText = encounterIDText
            self.ratio = ratio
            self.procedureCodeText = procedureCodeText
            self.description = description
            self.batchSize = batchSize
            self.priority = priority
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadOverrideView(_ item: TieredReadOverride) -> TieredReadOverrideView {
        return TieredReadOverrideView(
            code: item.code,
            label: item.label,
            bed: item.bed,
            encounterIDText: item.encounterID,
            ratio: String(format: "%.2f", item.ratio),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            description: Kit.Text.truncate(item.description, limit: 80),
            batchSize: String(item.batchSize),
            priority: String(item.priority),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadOverrideViews(_ items: [TieredReadOverride]) -> [TieredReadOverrideView] {
        var views: [TieredReadOverrideView] = []
        for item in items {
            views.append(toTieredReadOverrideView(item))
        }
        return views
    }

    static func sumTieredReadOverrideView(_ view: TieredReadOverrideView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedRatio + Double(parsedBatchSize) + Double(parsedPriority)
    }
}
