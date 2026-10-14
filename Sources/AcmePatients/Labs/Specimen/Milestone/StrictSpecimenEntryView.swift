import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict specimen entry.
    final class StrictSpecimenEntryView {
        var code: String
        var nameText: String
        var channel: String
        var weight: String
        var quantityText: String
        var retries: String
        var ceiling: String
        var title: String
        var budget: String
        var statusLabel: String

        init(code: String, nameText: String, channel: String, weight: String, quantityText: String, retries: String, ceiling: String, title: String, budget: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.channel = channel
            self.weight = weight
            self.quantityText = quantityText
            self.retries = retries
            self.ceiling = ceiling
            self.title = title
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSpecimenEntryView(_ item: StrictSpecimenEntry) -> StrictSpecimenEntryView {
        return StrictSpecimenEntryView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            channel: item.channel,
            weight: String(format: "%.2f", item.weight),
            quantityText: String(item.quantity),
            retries: String(item.retries),
            ceiling: String(format: "%.2f", item.ceiling),
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSpecimenEntryViews(_ items: [StrictSpecimenEntry]) -> [StrictSpecimenEntryView] {
        var views: [StrictSpecimenEntryView] = []
        for item in items {
            views.append(toStrictSpecimenEntryView(item))
        }
        return views
    }

    static func sumStrictSpecimenEntryView(_ view: StrictSpecimenEntryView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedWeight + Double(parsedQuantity) + Double(parsedRetries)
    }
}
