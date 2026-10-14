import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default transfer proposal.
    final class DefaultTransferProposalView {
        var code: String
        var label: String
        var cost: String
        var revisionText: String
        var contactEmail: String
        var source: String
        var currency: String
        var nameText: String
        var versionText: String
        var locale: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, cost: String, revisionText: String, contactEmail: String, source: String, currency: String, nameText: String, versionText: String, locale: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.revisionText = revisionText
            self.contactEmail = contactEmail
            self.source = source
            self.currency = currency
            self.nameText = nameText
            self.versionText = versionText
            self.locale = locale
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultTransferProposalView(_ item: DefaultTransferProposal) -> DefaultTransferProposalView {
        return DefaultTransferProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            revisionText: String(item.revision),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            source: Kit.Text.truncate(item.source, limit: 64),
            currency: item.currency,
            nameText: item.name,
            versionText: String(item.version),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultTransferProposalViews(_ items: [DefaultTransferProposal]) -> [DefaultTransferProposalView] {
        var views: [DefaultTransferProposalView] = []
        for item in items {
            views.append(toDefaultTransferProposalView(item))
        }
        return views
    }

    static func sumDefaultTransferProposalView(_ view: DefaultTransferProposalView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCost + Double(parsedRevision) + Double(parsedVersion)
    }
}
