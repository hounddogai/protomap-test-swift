import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan item.
    final class AcuityPlanItemView {
        var code: String
        var titleText: String
        var priorityText: String
        var segment: String
        var description: String
        var statusLabel: String

        init(code: String, titleText: String, priorityText: String, segment: String, description: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.priorityText = priorityText
            self.segment = segment
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanItemView(_ item: AcuityPlanItem) -> AcuityPlanItemView {
        return AcuityPlanItemView(
            code: item.code,
            titleText: item.title,
            priorityText: String(item.priority),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            description: Kit.Text.truncate(item.description, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanItemViews(_ items: [AcuityPlanItem]) -> [AcuityPlanItemView] {
        var views: [AcuityPlanItemView] = []
        for item in items {
            views.append(toAcuityPlanItemView(item))
        }
        return views
    }

    static func sumAcuityPlanItemView(_ view: AcuityPlanItemView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
