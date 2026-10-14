import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive dispense proposal.
    final class AdaptiveDispenseProposalView {
        var code: String
        var title: String
        var archived: String
        var endsAt: String
        var threshold: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, archived: String, endsAt: String, threshold: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.endsAt = endsAt
            self.threshold = threshold
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDispenseProposalView(_ item: AdaptiveDispenseProposal) -> AdaptiveDispenseProposalView {
        return AdaptiveDispenseProposalView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            archived: "\(item.archived)",
            endsAt: String(item.endsAt),
            threshold: String(format: "%.2f", item.threshold),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDispenseProposalViews(_ items: [AdaptiveDispenseProposal]) -> [AdaptiveDispenseProposalView] {
        var views: [AdaptiveDispenseProposalView] = []
        for item in items {
            views.append(toAdaptiveDispenseProposalView(item))
        }
        return views
    }

    static func sumAdaptiveDispenseProposalView(_ view: AdaptiveDispenseProposalView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedEndsAt) + parsedThreshold + Double(parsedLimit)
    }
}
