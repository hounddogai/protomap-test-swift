import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory segment.
    final class InventorySegmentView {
        var code: String
        var name: String
        var ratioText: String
        var reviewer: String
        var specialtyText: String
        var source: String
        var discount: String
        var unitText: String
        var statusLabel: String

        init(code: String, name: String, ratioText: String, reviewer: String, specialtyText: String, source: String, discount: String, unitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratioText = ratioText
            self.reviewer = reviewer
            self.specialtyText = specialtyText
            self.source = source
            self.discount = discount
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toInventorySegmentView(_ item: InventorySegment) -> InventorySegmentView {
        return InventorySegmentView(
            code: item.code,
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            reviewer: item.reviewer,
            specialtyText: item.specialty,
            source: item.source,
            discount: String(format: "%.2f", item.discount),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventorySegmentViews(_ items: [InventorySegment]) -> [InventorySegmentView] {
        var views: [InventorySegmentView] = []
        for item in items {
            views.append(toInventorySegmentView(item))
        }
        return views
    }

    static func sumInventorySegmentView(_ view: InventorySegmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRatio + parsedDiscount
    }
}
