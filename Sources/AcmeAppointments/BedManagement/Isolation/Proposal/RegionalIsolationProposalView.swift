import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional isolation proposal.
    final class RegionalIsolationProposalView {
        var code: String
        var title: String
        var marginText: String
        var limit: String
        var version: String
        var minimumText: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, limit: String, version: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.limit = limit
            self.version = version
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalIsolationProposalView(_ item: RegionalIsolationProposal) -> RegionalIsolationProposalView {
        return RegionalIsolationProposalView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            limit: String(item.limit),
            version: String(item.version),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalIsolationProposalViews(_ items: [RegionalIsolationProposal]) -> [RegionalIsolationProposalView] {
        var views: [RegionalIsolationProposalView] = []
        for item in items {
            views.append(toRegionalIsolationProposalView(item))
        }
        return views
    }

    static func sumRegionalIsolationProposalView(_ view: RegionalIsolationProposalView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMargin + Double(parsedLimit) + Double(parsedVersion)
    }
}
