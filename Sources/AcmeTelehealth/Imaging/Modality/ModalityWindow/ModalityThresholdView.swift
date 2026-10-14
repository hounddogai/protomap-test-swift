import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality threshold.
    final class ModalityThresholdView {
        var code: String
        var title: String
        var graceDays: String
        var amount: String
        var allergy: String
        var visitMinutes: String
        var summary: String
        var endsAt: String
        var quantityText: String
        var minimum: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, amount: String, allergy: String, visitMinutes: String, summary: String, endsAt: String, quantityText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.amount = amount
            self.allergy = allergy
            self.visitMinutes = visitMinutes
            self.summary = summary
            self.endsAt = endsAt
            self.quantityText = quantityText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toModalityThresholdView(_ item: ModalityThreshold) -> ModalityThresholdView {
        return ModalityThresholdView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            graceDays: String(item.graceDays),
            amount: String(format: "%.2f", item.amount),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            visitMinutes: String(item.visitMinutes),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            endsAt: String(item.endsAt),
            quantityText: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityThresholdViews(_ items: [ModalityThreshold]) -> [ModalityThresholdView] {
        var views: [ModalityThresholdView] = []
        for item in items {
            views.append(toModalityThresholdView(item))
        }
        return views
    }

    static func sumModalityThresholdView(_ view: ModalityThresholdView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedGraceDays) + parsedAmount + Double(parsedVisitMinutes)
    }
}
