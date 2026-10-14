import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending task proposal.
    final class PendingTaskProposalView {
        var code: String
        var label: String
        var patientRefText: String
        var pinned: String
        var description: String
        var copayText: String
        var statusLabel: String

        init(code: String, label: String, patientRefText: String, pinned: String, description: String, copayText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRefText = patientRefText
            self.pinned = pinned
            self.description = description
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingTaskProposalView(_ item: PendingTaskProposal) -> PendingTaskProposalView {
        return PendingTaskProposalView(
            code: item.code,
            label: item.label,
            patientRefText: item.patientRef,
            pinned: "\(item.pinned)",
            description: item.description,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingTaskProposalViews(_ items: [PendingTaskProposal]) -> [PendingTaskProposalView] {
        var views: [PendingTaskProposalView] = []
        for item in items {
            views.append(toPendingTaskProposalView(item))
        }
        return views
    }

    static func sumPendingTaskProposalView(_ view: PendingTaskProposalView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
