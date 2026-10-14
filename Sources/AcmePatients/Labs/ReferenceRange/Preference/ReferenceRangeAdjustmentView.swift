import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range adjustment.
    final class ReferenceRangeAdjustmentView {
        var code: String
        var label: String
        var unitText: String
        var currency: String
        var countryText: String
        var reviewerText: String
        var archivedText: String
        var floorValue: String
        var externalRef: String
        var statusLabel: String

        init(code: String, label: String, unitText: String, currency: String, countryText: String, reviewerText: String, archivedText: String, floorValue: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unitText = unitText
            self.currency = currency
            self.countryText = countryText
            self.reviewerText = reviewerText
            self.archivedText = archivedText
            self.floorValue = floorValue
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeAdjustmentView(_ item: ReferenceRangeAdjustment) -> ReferenceRangeAdjustmentView {
        return ReferenceRangeAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            unitText: item.unit,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            countryText: item.country,
            reviewerText: item.reviewer,
            archivedText: "\(item.archived)",
            floorValue: String(format: "%.2f", item.floorValue),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeAdjustmentViews(_ items: [ReferenceRangeAdjustment]) -> [ReferenceRangeAdjustmentView] {
        var views: [ReferenceRangeAdjustmentView] = []
        for item in items {
            views.append(toReferenceRangeAdjustmentView(item))
        }
        return views
    }

    static func sumReferenceRangeAdjustmentView(_ view: ReferenceRangeAdjustmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
