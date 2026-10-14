import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled acuity plan rule.
    final class ScheduledAcuityPlanRuleView {
        var code: String
        var labelText: String
        var phone: String
        var sequenceText: String
        var acuity: String
        var cost: String
        var ratioText: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, labelText: String, phone: String, sequenceText: String, acuity: String, cost: String, ratioText: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.phone = phone
            self.sequenceText = sequenceText
            self.acuity = acuity
            self.cost = cost
            self.ratioText = ratioText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAcuityPlanRuleView(_ item: ScheduledAcuityPlanRule) -> ScheduledAcuityPlanRuleView {
        return ScheduledAcuityPlanRuleView(
            code: item.code,
            labelText: item.label,
            phone: Kit.Text.truncate(item.phone, limit: 40),
            sequenceText: String(item.sequence),
            acuity: String(item.acuity),
            cost: String(format: "%.2f", item.cost),
            ratioText: String(format: "%.2f", item.ratio),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAcuityPlanRuleViews(_ items: [ScheduledAcuityPlanRule]) -> [ScheduledAcuityPlanRuleView] {
        var views: [ScheduledAcuityPlanRuleView] = []
        for item in items {
            views.append(toScheduledAcuityPlanRuleView(item))
        }
        return views
    }

    static func sumScheduledAcuityPlanRuleView(_ view: ScheduledAcuityPlanRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedSequence) + Double(parsedAcuity) + parsedCost
    }
}
