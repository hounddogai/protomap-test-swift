import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive bed board target.
    final class AdaptiveBedBoardTargetView {
        var codeText: String
        var title: String
        var categoryText: String
        var country: String
        var createdAt: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, title: String, categoryText: String, country: String, createdAt: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.categoryText = categoryText
            self.country = country
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveBedBoardTargetView(_ item: AdaptiveBedBoardTarget) -> AdaptiveBedBoardTargetView {
        return AdaptiveBedBoardTargetView(
            codeText: item.code,
            title: item.title,
            categoryText: item.category,
            country: Kit.Text.truncate(item.country, limit: 64),
            createdAt: String(item.createdAt),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveBedBoardTargetViews(_ items: [AdaptiveBedBoardTarget]) -> [AdaptiveBedBoardTargetView] {
        var views: [AdaptiveBedBoardTargetView] = []
        for item in items {
            views.append(toAdaptiveBedBoardTargetView(item))
        }
        return views
    }

    static func sumAdaptiveBedBoardTargetView(_ view: AdaptiveBedBoardTargetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
