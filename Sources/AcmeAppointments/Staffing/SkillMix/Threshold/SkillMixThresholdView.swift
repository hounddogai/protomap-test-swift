import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix threshold.
    final class SkillMixThresholdView {
        var codeText: String
        var title: String
        var encounterID: String
        var acuity: String
        var summaryText: String
        var region: String
        var channel: String
        var budgetText: String
        var bedText: String
        var notes: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, title: String, encounterID: String, acuity: String, summaryText: String, region: String, channel: String, budgetText: String, bedText: String, notes: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.encounterID = encounterID
            self.acuity = acuity
            self.summaryText = summaryText
            self.region = region
            self.channel = channel
            self.budgetText = budgetText
            self.bedText = bedText
            self.notes = notes
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixThresholdView(_ item: SkillMixThreshold) -> SkillMixThresholdView {
        return SkillMixThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            acuity: String(item.acuity),
            summaryText: item.summary,
            region: item.region,
            channel: item.channel,
            budgetText: String(format: "%.2f", item.budget),
            bedText: item.bed,
            notes: item.notes,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixThresholdViews(_ items: [SkillMixThreshold]) -> [SkillMixThresholdView] {
        var views: [SkillMixThresholdView] = []
        for item in items {
            views.append(toSkillMixThresholdView(item))
        }
        return views
    }

    static func sumSkillMixThresholdView(_ view: SkillMixThresholdView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAcuity) + parsedBudget
    }
}
