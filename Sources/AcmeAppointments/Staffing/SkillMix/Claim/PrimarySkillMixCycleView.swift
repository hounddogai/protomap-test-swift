import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary skill mix cycle.
    final class PrimarySkillMixCycleView {
        var codeText: String
        var name: String
        var title: String
        var attempts: String
        var diagnosisCode: String
        var rate: String
        var ceiling: String
        var localeText: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, attempts: String, diagnosisCode: String, rate: String, ceiling: String, localeText: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.ceiling = ceiling
            self.localeText = localeText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySkillMixCycleView(_ item: PrimarySkillMixCycle) -> PrimarySkillMixCycleView {
        return PrimarySkillMixCycleView(
            codeText: item.code,
            name: item.name,
            title: item.title,
            attempts: String(item.attempts),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            rate: String(format: "%.2f", item.rate),
            ceiling: String(format: "%.2f", item.ceiling),
            localeText: item.locale,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySkillMixCycleViews(_ items: [PrimarySkillMixCycle]) -> [PrimarySkillMixCycleView] {
        var views: [PrimarySkillMixCycleView] = []
        for item in items {
            views.append(toPrimarySkillMixCycleView(item))
        }
        return views
    }

    static func sumPrimarySkillMixCycleView(_ view: PrimarySkillMixCycleView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedAttempts) + parsedRate + parsedCeiling
    }
}
