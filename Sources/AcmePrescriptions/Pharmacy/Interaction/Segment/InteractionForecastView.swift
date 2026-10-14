import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction forecast.
    final class InteractionForecastView {
        var codeText: String
        var title: String
        var endsAt: String
        var notesText: String
        var dosageMg: String
        var capacityText: String
        var descriptionText: String
        var externalRefText: String
        var activeText: String
        var windowDays: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, title: String, endsAt: String, notesText: String, dosageMg: String, capacityText: String, descriptionText: String, externalRefText: String, activeText: String, windowDays: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAt = endsAt
            self.notesText = notesText
            self.dosageMg = dosageMg
            self.capacityText = capacityText
            self.descriptionText = descriptionText
            self.externalRefText = externalRefText
            self.activeText = activeText
            self.windowDays = windowDays
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionForecastView(_ item: InteractionForecast) -> InteractionForecastView {
        return InteractionForecastView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            endsAt: String(item.endsAt),
            notesText: item.notes,
            dosageMg: String(format: "%.2f", item.dosageMg),
            capacityText: String(item.capacity),
            descriptionText: item.description,
            externalRefText: item.externalRef,
            activeText: "\(item.active)",
            windowDays: String(item.windowDays),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionForecastViews(_ items: [InteractionForecast]) -> [InteractionForecastView] {
        var views: [InteractionForecastView] = []
        for item in items {
            views.append(toInteractionForecastView(item))
        }
        return views
    }

    static func sumInteractionForecastView(_ view: InteractionForecastView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedEndsAt) + parsedDosageMg + Double(parsedCapacity)
    }
}
