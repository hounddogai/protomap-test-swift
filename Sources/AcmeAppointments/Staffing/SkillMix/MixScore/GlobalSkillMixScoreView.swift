import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global skill mix score.
    final class GlobalSkillMixScoreView {
        var code: String
        var nameText: String
        var capacity: String
        var channel: String
        var diagnosisCode: String
        var windowDaysText: String
        var copay: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, capacity: String, channel: String, diagnosisCode: String, windowDaysText: String, copay: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.capacity = capacity
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.windowDaysText = windowDaysText
            self.copay = copay
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSkillMixScoreView(_ item: GlobalSkillMixScore) -> GlobalSkillMixScoreView {
        return GlobalSkillMixScoreView(
            code: item.code,
            nameText: item.name,
            capacity: String(item.capacity),
            channel: item.channel,
            diagnosisCode: item.diagnosisCode,
            windowDaysText: String(item.windowDays),
            copay: String(format: "%.2f", item.copay),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSkillMixScoreViews(_ items: [GlobalSkillMixScore]) -> [GlobalSkillMixScoreView] {
        var views: [GlobalSkillMixScoreView] = []
        for item in items {
            views.append(toGlobalSkillMixScoreView(item))
        }
        return views
    }

    static func sumGlobalSkillMixScoreView(_ view: GlobalSkillMixScoreView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + Double(parsedWindowDays) + parsedCopay
    }
}
