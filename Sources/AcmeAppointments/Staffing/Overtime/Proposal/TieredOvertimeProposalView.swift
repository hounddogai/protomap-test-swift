import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered overtime proposal.
    final class TieredOvertimeProposalView {
        var codeText: String
        var nameText: String
        var categoryText: String
        var expiresAtText: String
        var wardText: String
        var archivedText: String
        var specialtyText: String
        var unitText: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, nameText: String, categoryText: String, expiresAtText: String, wardText: String, archivedText: String, specialtyText: String, unitText: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.categoryText = categoryText
            self.expiresAtText = expiresAtText
            self.wardText = wardText
            self.archivedText = archivedText
            self.specialtyText = specialtyText
            self.unitText = unitText
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOvertimeProposalView(_ item: TieredOvertimeProposal) -> TieredOvertimeProposalView {
        return TieredOvertimeProposalView(
            codeText: item.code,
            nameText: item.name,
            categoryText: Kit.Text.truncate(item.category, limit: 80),
            expiresAtText: String(item.expiresAt),
            wardText: item.ward,
            archivedText: "\(item.archived)",
            specialtyText: item.specialty,
            unitText: item.unit,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOvertimeProposalViews(_ items: [TieredOvertimeProposal]) -> [TieredOvertimeProposalView] {
        var views: [TieredOvertimeProposalView] = []
        for item in items {
            views.append(toTieredOvertimeProposalView(item))
        }
        return views
    }

    static func sumTieredOvertimeProposalView(_ view: TieredOvertimeProposalView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
