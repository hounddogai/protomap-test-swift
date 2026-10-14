import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall proposal.
    final class RecallProposalView {
        var codeText: String
        var label: String
        var acuity: String
        var channel: String
        var timezone: String
        var country: String
        var margin: String
        var statusLabel: String

        init(codeText: String, label: String, acuity: String, channel: String, timezone: String, country: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.acuity = acuity
            self.channel = channel
            self.timezone = timezone
            self.country = country
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRecallProposalView(_ item: RecallProposal) -> RecallProposalView {
        return RecallProposalView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            acuity: String(item.acuity),
            channel: item.channel,
            timezone: item.timezone,
            country: item.country,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallProposalViews(_ items: [RecallProposal]) -> [RecallProposalView] {
        var views: [RecallProposalView] = []
        for item in items {
            views.append(toRecallProposalView(item))
        }
        return views
    }

    static func sumRecallProposalView(_ view: RecallProposalView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + parsedMargin
    }
}
