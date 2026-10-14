import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist batch.
    final class WorklistBatchView {
        var code: String
        var labelText: String
        var country: String
        var region: String
        var segment: String
        var thresholdText: String
        var unit: String
        var summary: String
        var budget: String
        var statusLabel: String

        init(code: String, labelText: String, country: String, region: String, segment: String, thresholdText: String, unit: String, summary: String, budget: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.country = country
            self.region = region
            self.segment = segment
            self.thresholdText = thresholdText
            self.unit = unit
            self.summary = summary
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistBatchView(_ item: WorklistBatch) -> WorklistBatchView {
        return WorklistBatchView(
            code: item.code,
            labelText: item.label,
            country: item.country,
            region: Kit.Text.truncate(item.region, limit: 80),
            segment: item.segment,
            thresholdText: String(format: "%.2f", item.threshold),
            unit: item.unit,
            summary: item.summary,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistBatchViews(_ items: [WorklistBatch]) -> [WorklistBatchView] {
        var views: [WorklistBatchView] = []
        for item in items {
            views.append(toWorklistBatchView(item))
        }
        return views
    }

    static func sumWorklistBatchView(_ view: WorklistBatchView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedThreshold + parsedBudget
    }
}
