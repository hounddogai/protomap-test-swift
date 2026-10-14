import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive accession proposal.
    final class AdaptiveAccessionProposalView {
        var code: String
        var label: String
        var bed: String
        var facility: String
        var limit: String
        var name: String
        var versionText: String
        var threshold: String
        var currency: String
        var amount: String
        var source: String
        var statusLabel: String

        init(code: String, label: String, bed: String, facility: String, limit: String, name: String, versionText: String, threshold: String, currency: String, amount: String, source: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.facility = facility
            self.limit = limit
            self.name = name
            self.versionText = versionText
            self.threshold = threshold
            self.currency = currency
            self.amount = amount
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAccessionProposalView(_ item: AdaptiveAccessionProposal) -> AdaptiveAccessionProposalView {
        return AdaptiveAccessionProposalView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            bed: item.bed,
            facility: item.facility,
            limit: String(item.limit),
            name: item.name,
            versionText: String(item.version),
            threshold: String(format: "%.2f", item.threshold),
            currency: item.currency,
            amount: String(format: "%.2f", item.amount),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAccessionProposalViews(_ items: [AdaptiveAccessionProposal]) -> [AdaptiveAccessionProposalView] {
        var views: [AdaptiveAccessionProposalView] = []
        for item in items {
            views.append(toAdaptiveAccessionProposalView(item))
        }
        return views
    }

    static func sumAdaptiveAccessionProposalView(_ view: AdaptiveAccessionProposalView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + Double(parsedVersion) + parsedThreshold
    }
}
