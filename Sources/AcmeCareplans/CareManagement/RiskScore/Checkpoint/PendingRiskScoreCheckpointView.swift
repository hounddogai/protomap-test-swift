import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending risk score checkpoint.
    final class PendingRiskScoreCheckpointView {
        var code: String
        var label: String
        var pinnedText: String
        var startsAt: String
        var externalRef: String
        var revision: String
        var segment: String
        var budget: String
        var currency: String
        var statusLabel: String

        init(code: String, label: String, pinnedText: String, startsAt: String, externalRef: String, revision: String, segment: String, budget: String, currency: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinnedText = pinnedText
            self.startsAt = startsAt
            self.externalRef = externalRef
            self.revision = revision
            self.segment = segment
            self.budget = budget
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRiskScoreCheckpointView(_ item: PendingRiskScoreCheckpoint) -> PendingRiskScoreCheckpointView {
        return PendingRiskScoreCheckpointView(
            code: item.code,
            label: item.label,
            pinnedText: "\(item.pinned)",
            startsAt: String(item.startsAt),
            externalRef: item.externalRef,
            revision: String(item.revision),
            segment: item.segment,
            budget: String(format: "%.2f", item.budget),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRiskScoreCheckpointViews(_ items: [PendingRiskScoreCheckpoint]) -> [PendingRiskScoreCheckpointView] {
        var views: [PendingRiskScoreCheckpointView] = []
        for item in items {
            views.append(toPendingRiskScoreCheckpointView(item))
        }
        return views
    }

    static func sumPendingRiskScoreCheckpointView(_ view: PendingRiskScoreCheckpointView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRevision) + parsedBudget
    }
}
