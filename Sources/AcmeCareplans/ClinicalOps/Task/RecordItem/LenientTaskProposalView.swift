import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient task proposal.
    final class LenientTaskProposalView {
        var code: String
        var label: String
        var notesText: String
        var allergy: String
        var expiresAt: String
        var versionText: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, notesText: String, allergy: String, expiresAt: String, versionText: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notesText = notesText
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.versionText = versionText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toLenientTaskProposalView(_ item: LenientTaskProposal) -> LenientTaskProposalView {
        return LenientTaskProposalView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            notesText: item.notes,
            allergy: item.allergy,
            expiresAt: String(item.expiresAt),
            versionText: String(item.version),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientTaskProposalViews(_ items: [LenientTaskProposal]) -> [LenientTaskProposalView] {
        var views: [LenientTaskProposalView] = []
        for item in items {
            views.append(toLenientTaskProposalView(item))
        }
        return views
    }

    static func sumLenientTaskProposalView(_ view: LenientTaskProposalView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedVersion) + parsedCost
    }
}
