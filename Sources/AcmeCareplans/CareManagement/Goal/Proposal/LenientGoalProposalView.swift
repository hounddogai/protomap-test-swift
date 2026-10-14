import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient goal proposal.
    final class LenientGoalProposalView {
        var codeText: String
        var labelText: String
        var timezone: String
        var unitText: String
        var thresholdText: String
        var createdAt: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, timezone: String, unitText: String, thresholdText: String, createdAt: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.timezone = timezone
            self.unitText = unitText
            self.thresholdText = thresholdText
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toLenientGoalProposalView(_ item: LenientGoalProposal) -> LenientGoalProposalView {
        return LenientGoalProposalView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            timezone: item.timezone,
            unitText: item.unit,
            thresholdText: String(format: "%.2f", item.threshold),
            createdAt: String(item.createdAt),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientGoalProposalViews(_ items: [LenientGoalProposal]) -> [LenientGoalProposalView] {
        var views: [LenientGoalProposalView] = []
        for item in items {
            views.append(toLenientGoalProposalView(item))
        }
        return views
    }

    static func sumLenientGoalProposalView(_ view: LenientGoalProposalView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedThreshold + Double(parsedCreatedAt) + Double(parsedVisitMinutes)
    }
}
