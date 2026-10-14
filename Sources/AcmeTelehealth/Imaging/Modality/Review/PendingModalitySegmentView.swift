import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending modality segment.
    final class PendingModalitySegmentView {
        var code: String
        var title: String
        var unit: String
        var visible: String
        var specialty: String
        var quantityText: String
        var budgetText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, title: String, unit: String, visible: String, specialty: String, quantityText: String, budgetText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.visible = visible
            self.specialty = specialty
            self.quantityText = quantityText
            self.budgetText = budgetText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toPendingModalitySegmentView(_ item: PendingModalitySegment) -> PendingModalitySegmentView {
        return PendingModalitySegmentView(
            code: item.code,
            title: item.title,
            unit: item.unit,
            visible: "\(item.visible)",
            specialty: item.specialty,
            quantityText: String(item.quantity),
            budgetText: String(format: "%.2f", item.budget),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingModalitySegmentViews(_ items: [PendingModalitySegment]) -> [PendingModalitySegmentView] {
        var views: [PendingModalitySegmentView] = []
        for item in items {
            views.append(toPendingModalitySegmentView(item))
        }
        return views
    }

    static func sumPendingModalitySegmentView(_ view: PendingModalitySegmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedQuantity) + parsedBudget
    }
}
