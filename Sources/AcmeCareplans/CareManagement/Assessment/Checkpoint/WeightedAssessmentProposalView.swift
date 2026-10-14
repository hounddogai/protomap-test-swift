import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted assessment proposal.
    final class WeightedAssessmentProposalView {
        var code: String
        var label: String
        var weight: String
        var windowDays: String
        var encounterID: String
        var statusLabel: String

        init(code: String, label: String, weight: String, windowDays: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.windowDays = windowDays
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAssessmentProposalView(_ item: WeightedAssessmentProposal) -> WeightedAssessmentProposalView {
        return WeightedAssessmentProposalView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            weight: String(format: "%.2f", item.weight),
            windowDays: String(item.windowDays),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAssessmentProposalViews(_ items: [WeightedAssessmentProposal]) -> [WeightedAssessmentProposalView] {
        var views: [WeightedAssessmentProposalView] = []
        for item in items {
            views.append(toWeightedAssessmentProposalView(item))
        }
        return views
    }

    static func sumWeightedAssessmentProposalView(_ view: WeightedAssessmentProposalView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedWeight + Double(parsedWindowDays)
    }
}
