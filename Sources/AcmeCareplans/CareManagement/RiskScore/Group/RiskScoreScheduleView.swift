import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score schedule.
    final class RiskScoreScheduleView {
        var codeText: String
        var name: String
        var patientRefText: String
        var expiresAt: String
        var bed: String
        var priority: String
        var limitText: String
        var payer: String
        var unit: String
        var statusLabel: String

        init(codeText: String, name: String, patientRefText: String, expiresAt: String, bed: String, priority: String, limitText: String, payer: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRefText = patientRefText
            self.expiresAt = expiresAt
            self.bed = bed
            self.priority = priority
            self.limitText = limitText
            self.payer = payer
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreScheduleView(_ item: RiskScoreSchedule) -> RiskScoreScheduleView {
        return RiskScoreScheduleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            patientRefText: item.patientRef,
            expiresAt: String(item.expiresAt),
            bed: item.bed,
            priority: String(item.priority),
            limitText: String(item.limit),
            payer: item.payer,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreScheduleViews(_ items: [RiskScoreSchedule]) -> [RiskScoreScheduleView] {
        var views: [RiskScoreScheduleView] = []
        for item in items {
            views.append(toRiskScoreScheduleView(item))
        }
        return views
    }

    static func sumRiskScoreScheduleView(_ view: RiskScoreScheduleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedPriority) + Double(parsedLimit)
    }
}
