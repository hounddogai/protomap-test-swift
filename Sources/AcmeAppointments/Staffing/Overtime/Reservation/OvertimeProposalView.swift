import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime proposal.
    final class OvertimeProposalView {
        var codeText: String
        var nameText: String
        var payerText: String
        var limit: String
        var batchSizeText: String
        var ownerID: String
        var bed: String
        var statusLabel: String

        init(codeText: String, nameText: String, payerText: String, limit: String, batchSizeText: String, ownerID: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.payerText = payerText
            self.limit = limit
            self.batchSizeText = batchSizeText
            self.ownerID = ownerID
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeProposalView(_ item: OvertimeProposal) -> OvertimeProposalView {
        return OvertimeProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            payerText: item.payer,
            limit: String(item.limit),
            batchSizeText: String(item.batchSize),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeProposalViews(_ items: [OvertimeProposal]) -> [OvertimeProposalView] {
        var views: [OvertimeProposalView] = []
        for item in items {
            views.append(toOvertimeProposalView(item))
        }
        return views
    }

    static func sumOvertimeProposalView(_ view: OvertimeProposalView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedLimit) + Double(parsedBatchSize)
    }
}
