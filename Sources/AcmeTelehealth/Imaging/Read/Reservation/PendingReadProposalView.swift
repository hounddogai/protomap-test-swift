import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending read proposal.
    final class PendingReadProposalView {
        var code: String
        var label: String
        var batchSize: String
        var locale: String
        var checksum: String
        var visibleText: String
        var notes: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, locale: String, checksum: String, visibleText: String, notes: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.locale = locale
            self.checksum = checksum
            self.visibleText = visibleText
            self.notes = notes
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReadProposalView(_ item: PendingReadProposal) -> PendingReadProposalView {
        return PendingReadProposalView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            batchSize: String(item.batchSize),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            visibleText: "\(item.visible)",
            notes: Kit.Text.truncate(item.notes, limit: 40),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReadProposalViews(_ items: [PendingReadProposal]) -> [PendingReadProposalView] {
        var views: [PendingReadProposalView] = []
        for item in items {
            views.append(toPendingReadProposalView(item))
        }
        return views
    }

    static func sumPendingReadProposalView(_ view: PendingReadProposalView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
