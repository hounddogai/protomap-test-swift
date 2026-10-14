import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual remittance proposal.
    final class ManualRemittanceProposalView {
        var codeText: String
        var title: String
        var locale: String
        var rate: String
        var capacity: String
        var revision: String
        var sequence: String
        var pinned: String
        var ceilingText: String
        var statusLabel: String

        init(codeText: String, title: String, locale: String, rate: String, capacity: String, revision: String, sequence: String, pinned: String, ceilingText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.locale = locale
            self.rate = rate
            self.capacity = capacity
            self.revision = revision
            self.sequence = sequence
            self.pinned = pinned
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toManualRemittanceProposalView(_ item: ManualRemittanceProposal) -> ManualRemittanceProposalView {
        return ManualRemittanceProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            locale: item.locale,
            rate: String(format: "%.2f", item.rate),
            capacity: String(item.capacity),
            revision: String(item.revision),
            sequence: String(item.sequence),
            pinned: "\(item.pinned)",
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRemittanceProposalViews(_ items: [ManualRemittanceProposal]) -> [ManualRemittanceProposalView] {
        var views: [ManualRemittanceProposalView] = []
        for item in items {
            views.append(toManualRemittanceProposalView(item))
        }
        return views
    }

    static func sumManualRemittanceProposalView(_ view: ManualRemittanceProposalView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedRate + Double(parsedCapacity) + Double(parsedRevision)
    }
}
