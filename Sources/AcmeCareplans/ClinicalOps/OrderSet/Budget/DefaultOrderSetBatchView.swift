import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default order set batch.
    final class DefaultOrderSetBatchView {
        var code: String
        var labelText: String
        var attempts: String
        var createdAt: String
        var channel: String
        var minimumText: String
        var floorValue: String
        var region: String
        var visibleText: String
        var titleText: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, labelText: String, attempts: String, createdAt: String, channel: String, minimumText: String, floorValue: String, region: String, visibleText: String, titleText: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.attempts = attempts
            self.createdAt = createdAt
            self.channel = channel
            self.minimumText = minimumText
            self.floorValue = floorValue
            self.region = region
            self.visibleText = visibleText
            self.titleText = titleText
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultOrderSetBatchView(_ item: DefaultOrderSetBatch) -> DefaultOrderSetBatchView {
        return DefaultOrderSetBatchView(
            code: item.code,
            labelText: item.label,
            attempts: String(item.attempts),
            createdAt: String(item.createdAt),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            region: item.region,
            visibleText: "\(item.visible)",
            titleText: item.title,
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultOrderSetBatchViews(_ items: [DefaultOrderSetBatch]) -> [DefaultOrderSetBatchView] {
        var views: [DefaultOrderSetBatchView] = []
        for item in items {
            views.append(toDefaultOrderSetBatchView(item))
        }
        return views
    }

    static func sumDefaultOrderSetBatchView(_ view: DefaultOrderSetBatchView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCreatedAt) + parsedMinimum
    }
}
