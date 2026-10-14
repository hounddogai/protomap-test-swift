import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff milestone.
    final class HandoffMilestoneView {
        var codeText: String
        var label: String
        var durationMinutesText: String
        var categoryText: String
        var updatedAtText: String
        var pinned: String
        var diagnosisCodeText: String
        var channelText: String
        var rate: String
        var statusLabel: String

        init(codeText: String, label: String, durationMinutesText: String, categoryText: String, updatedAtText: String, pinned: String, diagnosisCodeText: String, channelText: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.durationMinutesText = durationMinutesText
            self.categoryText = categoryText
            self.updatedAtText = updatedAtText
            self.pinned = pinned
            self.diagnosisCodeText = diagnosisCodeText
            self.channelText = channelText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffMilestoneView(_ item: HandoffMilestone) -> HandoffMilestoneView {
        return HandoffMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            durationMinutesText: String(item.durationMinutes),
            categoryText: item.category,
            updatedAtText: String(item.updatedAt),
            pinned: "\(item.pinned)",
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            channelText: item.channel,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffMilestoneViews(_ items: [HandoffMilestone]) -> [HandoffMilestoneView] {
        var views: [HandoffMilestoneView] = []
        for item in items {
            views.append(toHandoffMilestoneView(item))
        }
        return views
    }

    static func sumHandoffMilestoneView(_ view: HandoffMilestoneView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedUpdatedAt) + parsedRate
    }
}
