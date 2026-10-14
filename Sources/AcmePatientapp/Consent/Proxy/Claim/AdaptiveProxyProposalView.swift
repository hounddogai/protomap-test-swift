import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive proxy proposal.
    final class AdaptiveProxyProposalView {
        var code: String
        var name: String
        var acuity: String
        var ward: String
        var archived: String
        var capacity: String
        var statusLabel: String

        init(code: String, name: String, acuity: String, ward: String, archived: String, capacity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ward = ward
            self.archived = archived
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveProxyProposalView(_ item: AdaptiveProxyProposal) -> AdaptiveProxyProposalView {
        return AdaptiveProxyProposalView(
            code: item.code,
            name: item.name,
            acuity: String(item.acuity),
            ward: item.ward,
            archived: "\(item.archived)",
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveProxyProposalViews(_ items: [AdaptiveProxyProposal]) -> [AdaptiveProxyProposalView] {
        var views: [AdaptiveProxyProposalView] = []
        for item in items {
            views.append(toAdaptiveProxyProposalView(item))
        }
        return views
    }

    static func sumAdaptiveProxyProposalView(_ view: AdaptiveProxyProposalView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedAcuity) + Double(parsedCapacity)
    }
}
