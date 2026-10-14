import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy result proposal.
    final class LegacyResultProposalView {
        var codeText: String
        var title: String
        var copay: String
        var pinned: String
        var weight: String
        var expiresAt: String
        var encounterID: String
        var label: String
        var patientRef: String
        var batchSizeText: String
        var statusLabel: String

        init(codeText: String, title: String, copay: String, pinned: String, weight: String, expiresAt: String, encounterID: String, label: String, patientRef: String, batchSizeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.copay = copay
            self.pinned = pinned
            self.weight = weight
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.label = label
            self.patientRef = patientRef
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyResultProposalView(_ item: LegacyResultProposal) -> LegacyResultProposalView {
        return LegacyResultProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            copay: String(format: "%.2f", item.copay),
            pinned: "\(item.pinned)",
            weight: String(format: "%.2f", item.weight),
            expiresAt: String(item.expiresAt),
            encounterID: item.encounterID,
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyResultProposalViews(_ items: [LegacyResultProposal]) -> [LegacyResultProposalView] {
        var views: [LegacyResultProposalView] = []
        for item in items {
            views.append(toLegacyResultProposalView(item))
        }
        return views
    }

    static func sumLegacyResultProposalView(_ view: LegacyResultProposalView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCopay + parsedWeight + Double(parsedExpiresAt)
    }
}
