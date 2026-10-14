import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy goal proposal.
    final class LegacyGoalProposalView {
        var code: String
        var titleText: String
        var weight: String
        var source: String
        var retriesText: String
        var thresholdText: String
        var notes: String
        var checksum: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, titleText: String, weight: String, source: String, retriesText: String, thresholdText: String, notes: String, checksum: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weight = weight
            self.source = source
            self.retriesText = retriesText
            self.thresholdText = thresholdText
            self.notes = notes
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyGoalProposalView(_ item: LegacyGoalProposal) -> LegacyGoalProposalView {
        return LegacyGoalProposalView(
            code: item.code,
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            source: Kit.Text.truncate(item.source, limit: 80),
            retriesText: String(item.retries),
            thresholdText: String(format: "%.2f", item.threshold),
            notes: item.notes,
            checksum: item.checksum,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyGoalProposalViews(_ items: [LegacyGoalProposal]) -> [LegacyGoalProposalView] {
        var views: [LegacyGoalProposalView] = []
        for item in items {
            views.append(toLegacyGoalProposalView(item))
        }
        return views
    }

    static func sumLegacyGoalProposalView(_ view: LegacyGoalProposalView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedWeight + Double(parsedRetries) + parsedThreshold
    }
}
