import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped skill mix cycle.
    final class CappedSkillMixCycleView {
        var code: String
        var title: String
        var attemptsText: String
        var patientRef: String
        var limit: String
        var acuity: String
        var unit: String
        var allergyText: String
        var statusLabel: String

        init(code: String, title: String, attemptsText: String, patientRef: String, limit: String, acuity: String, unit: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attemptsText = attemptsText
            self.patientRef = patientRef
            self.limit = limit
            self.acuity = acuity
            self.unit = unit
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSkillMixCycleView(_ item: CappedSkillMixCycle) -> CappedSkillMixCycleView {
        return CappedSkillMixCycleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            attemptsText: String(item.attempts),
            patientRef: item.patientRef,
            limit: String(item.limit),
            acuity: String(item.acuity),
            unit: item.unit,
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSkillMixCycleViews(_ items: [CappedSkillMixCycle]) -> [CappedSkillMixCycleView] {
        var views: [CappedSkillMixCycleView] = []
        for item in items {
            views.append(toCappedSkillMixCycleView(item))
        }
        return views
    }

    static func sumCappedSkillMixCycleView(_ view: CappedSkillMixCycleView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit) + Double(parsedAcuity)
    }
}
