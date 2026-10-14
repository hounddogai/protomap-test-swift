import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary transfer proposal.
    final class PrimaryTransferProposalView {
        var codeText: String
        var nameText: String
        var diagnosisCode: String
        var source: String
        var locale: String
        var batchSizeText: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, nameText: String, diagnosisCode: String, source: String, locale: String, batchSizeText: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.locale = locale
            self.batchSizeText = batchSizeText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTransferProposalView(_ item: PrimaryTransferProposal) -> PrimaryTransferProposalView {
        return PrimaryTransferProposalView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            diagnosisCode: item.diagnosisCode,
            source: item.source,
            locale: item.locale,
            batchSizeText: String(item.batchSize),
            bedText: Kit.Text.truncate(item.bed, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTransferProposalViews(_ items: [PrimaryTransferProposal]) -> [PrimaryTransferProposalView] {
        var views: [PrimaryTransferProposalView] = []
        for item in items {
            views.append(toPrimaryTransferProposalView(item))
        }
        return views
    }

    static func sumPrimaryTransferProposalView(_ view: PrimaryTransferProposalView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
