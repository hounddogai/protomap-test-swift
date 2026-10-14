import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal priority mapping.
    final class SeasonalPriorityMappingView {
        var codeText: String
        var nameText: String
        var channel: String
        var ownerIDText: String
        var createdAt: String
        var category: String
        var segment: String
        var discount: String
        var locale: String
        var statusLabel: String

        init(codeText: String, nameText: String, channel: String, ownerIDText: String, createdAt: String, category: String, segment: String, discount: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.channel = channel
            self.ownerIDText = ownerIDText
            self.createdAt = createdAt
            self.category = category
            self.segment = segment
            self.discount = discount
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalPriorityMappingView(_ item: SeasonalPriorityMapping) -> SeasonalPriorityMappingView {
        return SeasonalPriorityMappingView(
            codeText: item.code,
            nameText: item.name,
            channel: item.channel,
            ownerIDText: item.ownerID,
            createdAt: String(item.createdAt),
            category: Kit.Text.truncate(item.category, limit: 120),
            segment: item.segment,
            discount: String(format: "%.2f", item.discount),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalPriorityMappingViews(_ items: [SeasonalPriorityMapping]) -> [SeasonalPriorityMappingView] {
        var views: [SeasonalPriorityMappingView] = []
        for item in items {
            views.append(toSeasonalPriorityMappingView(item))
        }
        return views
    }

    static func sumSeasonalPriorityMappingView(_ view: SeasonalPriorityMappingView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCreatedAt) + parsedDiscount
    }
}
