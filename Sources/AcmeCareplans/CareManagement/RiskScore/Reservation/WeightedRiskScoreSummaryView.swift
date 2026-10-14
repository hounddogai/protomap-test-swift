import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted risk score summary.
    final class WeightedRiskScoreSummaryView {
        var code: String
        var label: String
        var contactEmail: String
        var phone: String
        var margin: String
        var diagnosisCode: String
        var channel: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, contactEmail: String, phone: String, margin: String, diagnosisCode: String, channel: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.phone = phone
            self.margin = margin
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRiskScoreSummaryView(_ item: WeightedRiskScoreSummary) -> WeightedRiskScoreSummaryView {
        return WeightedRiskScoreSummaryView(
            code: item.code,
            label: item.label,
            contactEmail: item.contactEmail,
            phone: item.phone,
            margin: String(format: "%.2f", item.margin),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRiskScoreSummaryViews(_ items: [WeightedRiskScoreSummary]) -> [WeightedRiskScoreSummaryView] {
        var views: [WeightedRiskScoreSummaryView] = []
        for item in items {
            views.append(toWeightedRiskScoreSummaryView(item))
        }
        return views
    }

    static func sumWeightedRiskScoreSummaryView(_ view: WeightedRiskScoreSummaryView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedMargin + Double(parsedStartsAt)
    }
}
