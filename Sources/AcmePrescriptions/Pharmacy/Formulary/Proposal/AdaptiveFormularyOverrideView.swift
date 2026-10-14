import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive formulary override.
    final class AdaptiveFormularyOverrideView {
        var codeText: String
        var labelText: String
        var quantityText: String
        var weightText: String
        var active: String
        var approved: String
        var descriptionText: String
        var durationMinutesText: String
        var rate: String
        var statusLabel: String

        init(codeText: String, labelText: String, quantityText: String, weightText: String, active: String, approved: String, descriptionText: String, durationMinutesText: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.quantityText = quantityText
            self.weightText = weightText
            self.active = active
            self.approved = approved
            self.descriptionText = descriptionText
            self.durationMinutesText = durationMinutesText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFormularyOverrideView(_ item: AdaptiveFormularyOverride) -> AdaptiveFormularyOverrideView {
        return AdaptiveFormularyOverrideView(
            codeText: item.code,
            labelText: item.label,
            quantityText: String(item.quantity),
            weightText: String(format: "%.2f", item.weight),
            active: "\(item.active)",
            approved: "\(item.approved)",
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFormularyOverrideViews(_ items: [AdaptiveFormularyOverride]) -> [AdaptiveFormularyOverrideView] {
        var views: [AdaptiveFormularyOverrideView] = []
        for item in items {
            views.append(toAdaptiveFormularyOverrideView(item))
        }
        return views
    }

    static func sumAdaptiveFormularyOverrideView(_ view: AdaptiveFormularyOverrideView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedQuantity) + parsedWeight + Double(parsedDurationMinutes)
    }
}
