import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default courier proposal.
    final class DefaultCourierProposalView {
        var code: String
        var name: String
        var expiresAtText: String
        var rate: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, expiresAtText: String, rate: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAtText = expiresAtText
            self.rate = rate
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCourierProposalView(_ item: DefaultCourierProposal) -> DefaultCourierProposalView {
        return DefaultCourierProposalView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            expiresAtText: String(item.expiresAt),
            rate: String(format: "%.2f", item.rate),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCourierProposalViews(_ items: [DefaultCourierProposal]) -> [DefaultCourierProposalView] {
        var views: [DefaultCourierProposalView] = []
        for item in items {
            views.append(toDefaultCourierProposalView(item))
        }
        return views
    }

    static func sumDefaultCourierProposalView(_ view: DefaultCourierProposalView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + parsedRate
    }
}
