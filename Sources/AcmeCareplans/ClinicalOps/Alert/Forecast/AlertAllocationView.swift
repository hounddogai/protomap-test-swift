import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert allocation.
    final class AlertAllocationView {
        var code: String
        var labelText: String
        var encounterID: String
        var reviewer: String
        var priorityText: String
        var statusLabel: String

        init(code: String, labelText: String, encounterID: String, reviewer: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertAllocationView(_ item: AlertAllocation) -> AlertAllocationView {
        return AlertAllocationView(
            code: item.code,
            labelText: item.label,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            reviewer: item.reviewer,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertAllocationViews(_ items: [AlertAllocation]) -> [AlertAllocationView] {
        var views: [AlertAllocationView] = []
        for item in items {
            views.append(toAlertAllocationView(item))
        }
        return views
    }

    static func sumAlertAllocationView(_ view: AlertAllocationView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
