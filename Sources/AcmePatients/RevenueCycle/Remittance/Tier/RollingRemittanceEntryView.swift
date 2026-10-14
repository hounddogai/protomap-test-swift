import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling remittance entry.
    final class RollingRemittanceEntryView {
        var code: String
        var name: String
        var floorValue: String
        var categoryText: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, categoryText: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.categoryText = categoryText
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRemittanceEntryView(_ item: RollingRemittanceEntry) -> RollingRemittanceEntryView {
        return RollingRemittanceEntryView(
            code: item.code,
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            categoryText: item.category,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRemittanceEntryViews(_ items: [RollingRemittanceEntry]) -> [RollingRemittanceEntryView] {
        var views: [RollingRemittanceEntryView] = []
        for item in items {
            views.append(toRollingRemittanceEntryView(item))
        }
        return views
    }

    static func sumRollingRemittanceEntryView(_ view: RollingRemittanceEntryView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
