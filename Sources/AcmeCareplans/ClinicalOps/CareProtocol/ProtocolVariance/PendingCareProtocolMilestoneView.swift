import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending care protocol milestone.
    final class PendingCareProtocolMilestoneView {
        var codeText: String
        var nameText: String
        var sequence: String
        var thresholdText: String
        var budget: String
        var windowDays: String
        var externalRef: String
        var archivedText: String
        var createdAtText: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, nameText: String, sequence: String, thresholdText: String, budget: String, windowDays: String, externalRef: String, archivedText: String, createdAtText: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.sequence = sequence
            self.thresholdText = thresholdText
            self.budget = budget
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.archivedText = archivedText
            self.createdAtText = createdAtText
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCareProtocolMilestoneView(_ item: PendingCareProtocolMilestone) -> PendingCareProtocolMilestoneView {
        return PendingCareProtocolMilestoneView(
            codeText: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            thresholdText: String(format: "%.2f", item.threshold),
            budget: String(format: "%.2f", item.budget),
            windowDays: String(item.windowDays),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            archivedText: "\(item.archived)",
            createdAtText: String(item.createdAt),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCareProtocolMilestoneViews(_ items: [PendingCareProtocolMilestone]) -> [PendingCareProtocolMilestoneView] {
        var views: [PendingCareProtocolMilestoneView] = []
        for item in items {
            views.append(toPendingCareProtocolMilestoneView(item))
        }
        return views
    }

    static func sumPendingCareProtocolMilestoneView(_ view: PendingCareProtocolMilestoneView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedSequence) + parsedThreshold + parsedBudget
    }
}
