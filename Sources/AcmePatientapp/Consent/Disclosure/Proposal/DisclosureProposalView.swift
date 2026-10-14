import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure proposal.
    final class DisclosureProposalView {
        var code: String
        var label: String
        var endsAt: String
        var contactEmail: String
        var version: String
        var country: String
        var ownerID: String
        var ceiling: String
        var amount: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, endsAt: String, contactEmail: String, version: String, country: String, ownerID: String, ceiling: String, amount: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.version = version
            self.country = country
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.amount = amount
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureProposalView(_ item: DisclosureProposal) -> DisclosureProposalView {
        return DisclosureProposalView(
            code: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            contactEmail: item.contactEmail,
            version: String(item.version),
            country: item.country,
            ownerID: item.ownerID,
            ceiling: String(format: "%.2f", item.ceiling),
            amount: String(format: "%.2f", item.amount),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureProposalViews(_ items: [DisclosureProposal]) -> [DisclosureProposalView] {
        var views: [DisclosureProposalView] = []
        for item in items {
            views.append(toDisclosureProposalView(item))
        }
        return views
    }

    static func sumDisclosureProposalView(_ view: DisclosureProposalView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedVersion) + parsedCeiling
    }
}
