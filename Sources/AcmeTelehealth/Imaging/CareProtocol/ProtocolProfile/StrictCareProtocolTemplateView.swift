import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict care protocol template.
    final class StrictCareProtocolTemplateView {
        var code: String
        var label: String
        var approved: String
        var copayText: String
        var dosageMg: String
        var summaryText: String
        var capacityText: String
        var descriptionText: String
        var ratioText: String
        var statusLabel: String

        init(code: String, label: String, approved: String, copayText: String, dosageMg: String, summaryText: String, capacityText: String, descriptionText: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approved = approved
            self.copayText = copayText
            self.dosageMg = dosageMg
            self.summaryText = summaryText
            self.capacityText = capacityText
            self.descriptionText = descriptionText
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCareProtocolTemplateView(_ item: StrictCareProtocolTemplate) -> StrictCareProtocolTemplateView {
        return StrictCareProtocolTemplateView(
            code: item.code,
            label: item.label,
            approved: "\(item.approved)",
            copayText: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            summaryText: item.summary,
            capacityText: String(item.capacity),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCareProtocolTemplateViews(_ items: [StrictCareProtocolTemplate]) -> [StrictCareProtocolTemplateView] {
        var views: [StrictCareProtocolTemplateView] = []
        for item in items {
            views.append(toStrictCareProtocolTemplateView(item))
        }
        return views
    }

    static func sumStrictCareProtocolTemplateView(_ view: StrictCareProtocolTemplateView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCopay + parsedDosageMg + Double(parsedCapacity)
    }
}
