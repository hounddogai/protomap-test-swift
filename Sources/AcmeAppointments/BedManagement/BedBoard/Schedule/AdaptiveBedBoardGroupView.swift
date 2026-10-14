import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive bed board group.
    final class AdaptiveBedBoardGroupView {
        var code: String
        var title: String
        var expiresAtText: String
        var revisionText: String
        var country: String
        var segment: String
        var statusLabel: String

        init(code: String, title: String, expiresAtText: String, revisionText: String, country: String, segment: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAtText = expiresAtText
            self.revisionText = revisionText
            self.country = country
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveBedBoardGroupView(_ item: AdaptiveBedBoardGroup) -> AdaptiveBedBoardGroupView {
        return AdaptiveBedBoardGroupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            expiresAtText: String(item.expiresAt),
            revisionText: String(item.revision),
            country: item.country,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveBedBoardGroupViews(_ items: [AdaptiveBedBoardGroup]) -> [AdaptiveBedBoardGroupView] {
        var views: [AdaptiveBedBoardGroupView] = []
        for item in items {
            views.append(toAdaptiveBedBoardGroupView(item))
        }
        return views
    }

    static func sumAdaptiveBedBoardGroupView(_ view: AdaptiveBedBoardGroupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedRevision)
    }
}
