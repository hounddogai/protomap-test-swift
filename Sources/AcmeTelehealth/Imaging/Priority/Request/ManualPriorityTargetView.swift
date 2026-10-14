import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual priority target.
    final class ManualPriorityTargetView {
        var code: String
        var labelText: String
        var bedText: String
        var priority: String
        var allergy: String
        var country: String
        var statusLabel: String

        init(code: String, labelText: String, bedText: String, priority: String, allergy: String, country: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.bedText = bedText
            self.priority = priority
            self.allergy = allergy
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toManualPriorityTargetView(_ item: ManualPriorityTarget) -> ManualPriorityTargetView {
        return ManualPriorityTargetView(
            code: item.code,
            labelText: item.label,
            bedText: item.bed,
            priority: String(item.priority),
            allergy: item.allergy,
            country: Kit.Text.truncate(item.country, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualPriorityTargetViews(_ items: [ManualPriorityTarget]) -> [ManualPriorityTargetView] {
        var views: [ManualPriorityTargetView] = []
        for item in items {
            views.append(toManualPriorityTargetView(item))
        }
        return views
    }

    static func sumManualPriorityTargetView(_ view: ManualPriorityTargetView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
