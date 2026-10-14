import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive slot manifest.
    final class AdaptiveSlotManifestView {
        var codeText: String
        var name: String
        var priorityText: String
        var ceilingText: String
        var title: String
        var weight: String
        var marginText: String
        var statusLabel: String

        init(codeText: String, name: String, priorityText: String, ceilingText: String, title: String, weight: String, marginText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.priorityText = priorityText
            self.ceilingText = ceilingText
            self.title = title
            self.weight = weight
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSlotManifestView(_ item: AdaptiveSlotManifest) -> AdaptiveSlotManifestView {
        return AdaptiveSlotManifestView(
            codeText: item.code,
            name: item.name,
            priorityText: String(item.priority),
            ceilingText: String(format: "%.2f", item.ceiling),
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSlotManifestViews(_ items: [AdaptiveSlotManifest]) -> [AdaptiveSlotManifestView] {
        var views: [AdaptiveSlotManifestView] = []
        for item in items {
            views.append(toAdaptiveSlotManifestView(item))
        }
        return views
    }

    static func sumAdaptiveSlotManifestView(_ view: AdaptiveSlotManifestView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedPriority) + parsedCeiling + parsedWeight
    }
}
