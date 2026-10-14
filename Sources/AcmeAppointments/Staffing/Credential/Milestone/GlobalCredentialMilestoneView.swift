import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global credential milestone.
    final class GlobalCredentialMilestoneView {
        var code: String
        var titleText: String
        var name: String
        var retries: String
        var pinnedText: String
        var priority: String
        var allergy: String
        var segment: String
        var floorValue: String
        var discount: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, name: String, retries: String, pinnedText: String, priority: String, allergy: String, segment: String, floorValue: String, discount: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.name = name
            self.retries = retries
            self.pinnedText = pinnedText
            self.priority = priority
            self.allergy = allergy
            self.segment = segment
            self.floorValue = floorValue
            self.discount = discount
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCredentialMilestoneView(_ item: GlobalCredentialMilestone) -> GlobalCredentialMilestoneView {
        return GlobalCredentialMilestoneView(
            code: item.code,
            titleText: item.title,
            name: Kit.Text.truncate(item.name, limit: 40),
            retries: String(item.retries),
            pinnedText: "\(item.pinned)",
            priority: String(item.priority),
            allergy: item.allergy,
            segment: item.segment,
            floorValue: String(format: "%.2f", item.floorValue),
            discount: String(format: "%.2f", item.discount),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCredentialMilestoneViews(_ items: [GlobalCredentialMilestone]) -> [GlobalCredentialMilestoneView] {
        var views: [GlobalCredentialMilestoneView] = []
        for item in items {
            views.append(toGlobalCredentialMilestoneView(item))
        }
        return views
    }

    static func sumGlobalCredentialMilestoneView(_ view: GlobalCredentialMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRetries) + Double(parsedPriority) + parsedFloorValue
    }
}
