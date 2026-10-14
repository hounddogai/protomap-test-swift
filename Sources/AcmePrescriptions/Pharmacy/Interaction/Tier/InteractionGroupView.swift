import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction group.
    final class InteractionGroupView {
        var code: String
        var label: String
        var updatedAtText: String
        var priority: String
        var regionText: String
        var locale: String
        var ceiling: String
        var sourceText: String
        var ward: String
        var statusLabel: String

        init(code: String, label: String, updatedAtText: String, priority: String, regionText: String, locale: String, ceiling: String, sourceText: String, ward: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAtText = updatedAtText
            self.priority = priority
            self.regionText = regionText
            self.locale = locale
            self.ceiling = ceiling
            self.sourceText = sourceText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionGroupView(_ item: InteractionGroup) -> InteractionGroupView {
        return InteractionGroupView(
            code: item.code,
            label: item.label,
            updatedAtText: String(item.updatedAt),
            priority: String(item.priority),
            regionText: item.region,
            locale: Kit.Text.truncate(item.locale, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            sourceText: item.source,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionGroupViews(_ items: [InteractionGroup]) -> [InteractionGroupView] {
        var views: [InteractionGroupView] = []
        for item in items {
            views.append(toInteractionGroupView(item))
        }
        return views
    }

    static func sumInteractionGroupView(_ view: InteractionGroupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedPriority) + parsedCeiling
    }
}
