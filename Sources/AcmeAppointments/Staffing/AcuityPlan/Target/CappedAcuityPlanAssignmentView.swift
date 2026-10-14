import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped acuity plan assignment.
    final class CappedAcuityPlanAssignmentView {
        var code: String
        var title: String
        var bed: String
        var acuity: String
        var priorityText: String
        var payer: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, bed: String, acuity: String, priorityText: String, payer: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bed = bed
            self.acuity = acuity
            self.priorityText = priorityText
            self.payer = payer
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toCappedAcuityPlanAssignmentView(_ item: CappedAcuityPlanAssignment) -> CappedAcuityPlanAssignmentView {
        return CappedAcuityPlanAssignmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            bed: item.bed,
            acuity: String(item.acuity),
            priorityText: String(item.priority),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedAcuityPlanAssignmentViews(_ items: [CappedAcuityPlanAssignment]) -> [CappedAcuityPlanAssignmentView] {
        var views: [CappedAcuityPlanAssignmentView] = []
        for item in items {
            views.append(toCappedAcuityPlanAssignmentView(item))
        }
        return views
    }

    static func sumCappedAcuityPlanAssignmentView(_ view: CappedAcuityPlanAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAcuity) + Double(parsedPriority) + Double(parsedLimit)
    }
}
