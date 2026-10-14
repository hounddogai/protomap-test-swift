import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual overtime proposal.
    final class ManualOvertimeProposalView {
        var codeText: String
        var name: String
        var payer: String
        var attempts: String
        var archived: String
        var pinned: String
        var allergyText: String
        var checksumText: String
        var ratio: String
        var bed: String
        var statusLabel: String

        init(codeText: String, name: String, payer: String, attempts: String, archived: String, pinned: String, allergyText: String, checksumText: String, ratio: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payer = payer
            self.attempts = attempts
            self.archived = archived
            self.pinned = pinned
            self.allergyText = allergyText
            self.checksumText = checksumText
            self.ratio = ratio
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toManualOvertimeProposalView(_ item: ManualOvertimeProposal) -> ManualOvertimeProposalView {
        return ManualOvertimeProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            attempts: String(item.attempts),
            archived: "\(item.archived)",
            pinned: "\(item.pinned)",
            allergyText: item.allergy,
            checksumText: item.checksum,
            ratio: String(format: "%.2f", item.ratio),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualOvertimeProposalViews(_ items: [ManualOvertimeProposal]) -> [ManualOvertimeProposalView] {
        var views: [ManualOvertimeProposalView] = []
        for item in items {
            views.append(toManualOvertimeProposalView(item))
        }
        return views
    }

    static func sumManualOvertimeProposalView(_ view: ManualOvertimeProposalView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + parsedRatio
    }
}
