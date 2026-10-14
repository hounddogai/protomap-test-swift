import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal entry.
    final class GoalEntryView {
        var code: String
        var title: String
        var windowDaysText: String
        var visibleText: String
        var copayText: String
        var facilityText: String
        var batchSize: String
        var encounterID: String
        var statusLabel: String

        init(code: String, title: String, windowDaysText: String, visibleText: String, copayText: String, facilityText: String, batchSize: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDaysText = windowDaysText
            self.visibleText = visibleText
            self.copayText = copayText
            self.facilityText = facilityText
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toGoalEntryView(_ item: GoalEntry) -> GoalEntryView {
        return GoalEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            windowDaysText: String(item.windowDays),
            visibleText: "\(item.visible)",
            copayText: String(format: "%.2f", item.copay),
            facilityText: item.facility,
            batchSize: String(item.batchSize),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalEntryViews(_ items: [GoalEntry]) -> [GoalEntryView] {
        var views: [GoalEntryView] = []
        for item in items {
            views.append(toGoalEntryView(item))
        }
        return views
    }

    static func sumGoalEntryView(_ view: GoalEntryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + parsedCopay + Double(parsedBatchSize)
    }
}
