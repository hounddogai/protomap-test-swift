import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient network notice.
    final class LenientNetworkNoticeView {
        var code: String
        var titleText: String
        var unit: String
        var updatedAt: String
        var archived: String
        var sourceText: String
        var ceiling: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, unit: String, updatedAt: String, archived: String, sourceText: String, ceiling: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.unit = unit
            self.updatedAt = updatedAt
            self.archived = archived
            self.sourceText = sourceText
            self.ceiling = ceiling
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toLenientNetworkNoticeView(_ item: LenientNetworkNotice) -> LenientNetworkNoticeView {
        return LenientNetworkNoticeView(
            code: item.code,
            titleText: item.title,
            unit: item.unit,
            updatedAt: String(item.updatedAt),
            archived: "\(item.archived)",
            sourceText: Kit.Text.truncate(item.source, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientNetworkNoticeViews(_ items: [LenientNetworkNotice]) -> [LenientNetworkNoticeView] {
        var views: [LenientNetworkNoticeView] = []
        for item in items {
            views.append(toLenientNetworkNoticeView(item))
        }
        return views
    }

    static func sumLenientNetworkNoticeView(_ view: LenientNetworkNoticeView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCeiling
    }
}
