import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default care protocol proposal.
    final class DefaultCareProtocolProposalView {
        var code: String
        var title: String
        var retriesText: String
        var refillsText: String
        var copayText: String
        var regionText: String
        var statusLabel: String

        init(code: String, title: String, retriesText: String, refillsText: String, copayText: String, regionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retriesText = retriesText
            self.refillsText = refillsText
            self.copayText = copayText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolProposalView(_ item: DefaultCareProtocolProposal) -> DefaultCareProtocolProposalView {
        return DefaultCareProtocolProposalView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            retriesText: String(item.retries),
            refillsText: String(item.refills),
            copayText: String(format: "%.2f", item.copay),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolProposalViews(_ items: [DefaultCareProtocolProposal]) -> [DefaultCareProtocolProposalView] {
        var views: [DefaultCareProtocolProposalView] = []
        for item in items {
            views.append(toDefaultCareProtocolProposalView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolProposalView(_ view: DefaultCareProtocolProposalView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRetries) + Double(parsedRefills) + parsedCopay
    }
}
