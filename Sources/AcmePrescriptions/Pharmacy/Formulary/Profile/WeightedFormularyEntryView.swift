import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted formulary entry.
    final class WeightedFormularyEntryView {
        var code: String
        var title: String
        var updatedAt: String
        var sequence: String
        var visitMinutesText: String
        var amountText: String
        var visibleText: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, sequence: String, visitMinutesText: String, amountText: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.sequence = sequence
            self.visitMinutesText = visitMinutesText
            self.amountText = amountText
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFormularyEntryView(_ item: WeightedFormularyEntry) -> WeightedFormularyEntryView {
        return WeightedFormularyEntryView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            updatedAt: String(item.updatedAt),
            sequence: String(item.sequence),
            visitMinutesText: String(item.visitMinutes),
            amountText: String(format: "%.2f", item.amount),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFormularyEntryViews(_ items: [WeightedFormularyEntry]) -> [WeightedFormularyEntryView] {
        var views: [WeightedFormularyEntryView] = []
        for item in items {
            views.append(toWeightedFormularyEntryView(item))
        }
        return views
    }

    static func sumWeightedFormularyEntryView(_ view: WeightedFormularyEntryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedSequence) + Double(parsedVisitMinutes)
    }
}
