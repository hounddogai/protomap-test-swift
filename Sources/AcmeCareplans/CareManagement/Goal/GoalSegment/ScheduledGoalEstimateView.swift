import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled goal estimate.
    final class ScheduledGoalEstimateView {
        var code: String
        var nameText: String
        var archivedText: String
        var region: String
        var dosageMgText: String
        var category: String
        var batchSize: String
        var reviewer: String
        var locale: String
        var externalRef: String
        var visible: String
        var statusLabel: String

        init(code: String, nameText: String, archivedText: String, region: String, dosageMgText: String, category: String, batchSize: String, reviewer: String, locale: String, externalRef: String, visible: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.archivedText = archivedText
            self.region = region
            self.dosageMgText = dosageMgText
            self.category = category
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.locale = locale
            self.externalRef = externalRef
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledGoalEstimateView(_ item: ScheduledGoalEstimate) -> ScheduledGoalEstimateView {
        return ScheduledGoalEstimateView(
            code: item.code,
            nameText: item.name,
            archivedText: "\(item.archived)",
            region: item.region,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            category: item.category,
            batchSize: String(item.batchSize),
            reviewer: item.reviewer,
            locale: item.locale,
            externalRef: item.externalRef,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledGoalEstimateViews(_ items: [ScheduledGoalEstimate]) -> [ScheduledGoalEstimateView] {
        var views: [ScheduledGoalEstimateView] = []
        for item in items {
            views.append(toScheduledGoalEstimateView(item))
        }
        return views
    }

    static func sumScheduledGoalEstimateView(_ view: ScheduledGoalEstimateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedDosageMg + Double(parsedBatchSize)
    }
}
