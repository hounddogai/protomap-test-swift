import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility proposal.
    final class EligibilityProposalView {
        var codeText: String
        var labelText: String
        var batchSize: String
        var visitMinutesText: String
        var channel: String
        var diagnosisCode: String
        var reviewer: String
        var minimum: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, labelText: String, batchSize: String, visitMinutesText: String, channel: String, diagnosisCode: String, reviewer: String, minimum: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.batchSize = batchSize
            self.visitMinutesText = visitMinutesText
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.reviewer = reviewer
            self.minimum = minimum
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityProposalView(_ item: EligibilityProposal) -> EligibilityProposalView {
        return EligibilityProposalView(
            codeText: item.code,
            labelText: item.label,
            batchSize: String(item.batchSize),
            visitMinutesText: String(item.visitMinutes),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            reviewer: item.reviewer,
            minimum: String(format: "%.2f", item.minimum),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityProposalViews(_ items: [EligibilityProposal]) -> [EligibilityProposalView] {
        var views: [EligibilityProposalView] = []
        for item in items {
            views.append(toEligibilityProposalView(item))
        }
        return views
    }

    static func sumEligibilityProposalView(_ view: EligibilityProposalView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVisitMinutes) + parsedMinimum
    }
}
