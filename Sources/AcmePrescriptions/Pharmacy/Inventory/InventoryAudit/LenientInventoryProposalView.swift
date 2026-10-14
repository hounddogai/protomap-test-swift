import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient inventory proposal.
    final class LenientInventoryProposalView {
        var code: String
        var label: String
        var source: String
        var capacity: String
        var encounterID: String
        var reviewer: String
        var patientRef: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, source: String, capacity: String, encounterID: String, reviewer: String, patientRef: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.capacity = capacity
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInventoryProposalView(_ item: LenientInventoryProposal) -> LenientInventoryProposalView {
        return LenientInventoryProposalView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            source: Kit.Text.truncate(item.source, limit: 40),
            capacity: String(item.capacity),
            encounterID: item.encounterID,
            reviewer: item.reviewer,
            patientRef: item.patientRef,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInventoryProposalViews(_ items: [LenientInventoryProposal]) -> [LenientInventoryProposalView] {
        var views: [LenientInventoryProposalView] = []
        for item in items {
            views.append(toLenientInventoryProposalView(item))
        }
        return views
    }

    static func sumLenientInventoryProposalView(_ view: LenientInventoryProposalView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
