import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range proposal.
    final class ReferenceRangeProposalView {
        var code: String
        var title: String
        var budget: String
        var ratio: String
        var phone: String
        var statusLabel: String

        init(code: String, title: String, budget: String, ratio: String, phone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ratio = ratio
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeProposalView(_ item: ReferenceRangeProposal) -> ReferenceRangeProposalView {
        return ReferenceRangeProposalView(
            code: item.code,
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            ratio: String(format: "%.2f", item.ratio),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeProposalViews(_ items: [ReferenceRangeProposal]) -> [ReferenceRangeProposalView] {
        var views: [ReferenceRangeProposalView] = []
        for item in items {
            views.append(toReferenceRangeProposalView(item))
        }
        return views
    }

    static func sumReferenceRangeProposalView(_ view: ReferenceRangeProposalView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedBudget + parsedRatio
    }
}
