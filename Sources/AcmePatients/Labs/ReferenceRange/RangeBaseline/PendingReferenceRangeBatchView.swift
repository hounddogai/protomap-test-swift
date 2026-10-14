import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending reference range batch.
    final class PendingReferenceRangeBatchView {
        var codeText: String
        var titleText: String
        var allergyText: String
        var refills: String
        var minimum: String
        var category: String
        var maximum: String
        var discount: String
        var visible: String
        var statusLabel: String

        init(codeText: String, titleText: String, allergyText: String, refills: String, minimum: String, category: String, maximum: String, discount: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.allergyText = allergyText
            self.refills = refills
            self.minimum = minimum
            self.category = category
            self.maximum = maximum
            self.discount = discount
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferenceRangeBatchView(_ item: PendingReferenceRangeBatch) -> PendingReferenceRangeBatchView {
        return PendingReferenceRangeBatchView(
            codeText: item.code,
            titleText: item.title,
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            refills: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            category: item.category,
            maximum: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferenceRangeBatchViews(_ items: [PendingReferenceRangeBatch]) -> [PendingReferenceRangeBatchView] {
        var views: [PendingReferenceRangeBatchView] = []
        for item in items {
            views.append(toPendingReferenceRangeBatchView(item))
        }
        return views
    }

    static func sumPendingReferenceRangeBatchView(_ view: PendingReferenceRangeBatchView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRefills) + parsedMinimum + parsedMaximum
    }
}
