import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped proxy proposal.
    final class CappedProxyProposalView {
        var code: String
        var nameText: String
        var phoneText: String
        var acuityText: String
        var channelText: String
        var statusLabel: String

        init(code: String, nameText: String, phoneText: String, acuityText: String, channelText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phoneText = phoneText
            self.acuityText = acuityText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedProxyProposalView(_ item: CappedProxyProposal) -> CappedProxyProposalView {
        return CappedProxyProposalView(
            code: item.code,
            nameText: item.name,
            phoneText: Kit.Text.truncate(item.phone, limit: 120),
            acuityText: String(item.acuity),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedProxyProposalViews(_ items: [CappedProxyProposal]) -> [CappedProxyProposalView] {
        var views: [CappedProxyProposalView] = []
        for item in items {
            views.append(toCappedProxyProposalView(item))
        }
        return views
    }

    static func sumCappedProxyProposalView(_ view: CappedProxyProposalView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
