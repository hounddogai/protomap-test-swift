import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read quota.
    final class TieredReadQuotaView {
        var codeText: String
        var title: String
        var endsAtText: String
        var startsAt: String
        var locale: String
        var marginText: String
        var channelText: String
        var approvedText: String
        var score: String
        var versionText: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, title: String, endsAtText: String, startsAt: String, locale: String, marginText: String, channelText: String, approvedText: String, score: String, versionText: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAtText = endsAtText
            self.startsAt = startsAt
            self.locale = locale
            self.marginText = marginText
            self.channelText = channelText
            self.approvedText = approvedText
            self.score = score
            self.versionText = versionText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadQuotaView(_ item: TieredReadQuota) -> TieredReadQuotaView {
        return TieredReadQuotaView(
            codeText: item.code,
            title: item.title,
            endsAtText: String(item.endsAt),
            startsAt: String(item.startsAt),
            locale: item.locale,
            marginText: String(format: "%.2f", item.margin),
            channelText: item.channel,
            approvedText: "\(item.approved)",
            score: String(format: "%.2f", item.score),
            versionText: String(item.version),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadQuotaViews(_ items: [TieredReadQuota]) -> [TieredReadQuotaView] {
        var views: [TieredReadQuotaView] = []
        for item in items {
            views.append(toTieredReadQuotaView(item))
        }
        return views
    }

    static func sumTieredReadQuotaView(_ view: TieredReadQuotaView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedStartsAt) + parsedMargin
    }
}
