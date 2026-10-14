import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial rollup.
    final class DenialRollupView {
        var code: String
        var name: String
        var description: String
        var marginText: String
        var unit: String
        var externalRef: String
        var ownerID: String
        var statusLabel: String

        init(code: String, name: String, description: String, marginText: String, unit: String, externalRef: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.description = description
            self.marginText = marginText
            self.unit = unit
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toDenialRollupView(_ item: DenialRollup) -> DenialRollupView {
        return DenialRollupView(
            code: item.code,
            name: item.name,
            description: item.description,
            marginText: String(format: "%.2f", item.margin),
            unit: item.unit,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialRollupViews(_ items: [DenialRollup]) -> [DenialRollupView] {
        var views: [DenialRollupView] = []
        for item in items {
            views.append(toDenialRollupView(item))
        }
        return views
    }

    static func sumDenialRollupView(_ view: DenialRollupView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
