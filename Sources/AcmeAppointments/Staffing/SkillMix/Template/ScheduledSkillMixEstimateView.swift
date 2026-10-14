import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled skill mix estimate.
    final class ScheduledSkillMixEstimateView {
        var code: String
        var label: String
        var amount: String
        var description: String
        var specialty: String
        var sequence: String
        var score: String
        var country: String
        var copayText: String
        var segment: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, amount: String, description: String, specialty: String, sequence: String, score: String, country: String, copayText: String, segment: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amount = amount
            self.description = description
            self.specialty = specialty
            self.sequence = sequence
            self.score = score
            self.country = country
            self.copayText = copayText
            self.segment = segment
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledSkillMixEstimateView(_ item: ScheduledSkillMixEstimate) -> ScheduledSkillMixEstimateView {
        return ScheduledSkillMixEstimateView(
            code: item.code,
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            description: item.description,
            specialty: item.specialty,
            sequence: String(item.sequence),
            score: String(format: "%.2f", item.score),
            country: item.country,
            copayText: String(format: "%.2f", item.copay),
            segment: item.segment,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledSkillMixEstimateViews(_ items: [ScheduledSkillMixEstimate]) -> [ScheduledSkillMixEstimateView] {
        var views: [ScheduledSkillMixEstimateView] = []
        for item in items {
            views.append(toScheduledSkillMixEstimateView(item))
        }
        return views
    }

    static func sumScheduledSkillMixEstimateView(_ view: ScheduledSkillMixEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedAmount + Double(parsedSequence) + parsedScore
    }
}
