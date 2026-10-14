import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task allocation.
    final class TaskAllocationView {
        var codeText: String
        var labelText: String
        var localeText: String
        var encounterID: String
        var ratio: String
        var phone: String
        var statusLabel: String

        init(codeText: String, labelText: String, localeText: String, encounterID: String, ratio: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.localeText = localeText
            self.encounterID = encounterID
            self.ratio = ratio
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toTaskAllocationView(_ item: TaskAllocation) -> TaskAllocationView {
        return TaskAllocationView(
            codeText: item.code,
            labelText: item.label,
            localeText: Kit.Text.truncate(item.locale, limit: 80),
            encounterID: item.encounterID,
            ratio: String(format: "%.2f", item.ratio),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskAllocationViews(_ items: [TaskAllocation]) -> [TaskAllocationView] {
        var views: [TaskAllocationView] = []
        for item in items {
            views.append(toTaskAllocationView(item))
        }
        return views
    }

    static func sumTaskAllocationView(_ view: TaskAllocationView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
