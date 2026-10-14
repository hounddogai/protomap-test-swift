import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default bed board baseline.
    final class DefaultBedBoardBaselineView {
        var code: String
        var name: String
        var acuityText: String
        var channel: String
        var country: String
        var endsAt: String
        var localeText: String
        var updatedAtText: String
        var graceDays: String
        var retriesText: String
        var statusLabel: String

        init(code: String, name: String, acuityText: String, channel: String, country: String, endsAt: String, localeText: String, updatedAtText: String, graceDays: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuityText = acuityText
            self.channel = channel
            self.country = country
            self.endsAt = endsAt
            self.localeText = localeText
            self.updatedAtText = updatedAtText
            self.graceDays = graceDays
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultBedBoardBaselineView(_ item: DefaultBedBoardBaseline) -> DefaultBedBoardBaselineView {
        return DefaultBedBoardBaselineView(
            code: item.code,
            name: item.name,
            acuityText: String(item.acuity),
            channel: item.channel,
            country: Kit.Text.truncate(item.country, limit: 80),
            endsAt: String(item.endsAt),
            localeText: item.locale,
            updatedAtText: String(item.updatedAt),
            graceDays: String(item.graceDays),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultBedBoardBaselineViews(_ items: [DefaultBedBoardBaseline]) -> [DefaultBedBoardBaselineView] {
        var views: [DefaultBedBoardBaselineView] = []
        for item in items {
            views.append(toDefaultBedBoardBaselineView(item))
        }
        return views
    }

    static func sumDefaultBedBoardBaselineView(_ view: DefaultBedBoardBaselineView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedEndsAt) + Double(parsedUpdatedAt)
    }
}
