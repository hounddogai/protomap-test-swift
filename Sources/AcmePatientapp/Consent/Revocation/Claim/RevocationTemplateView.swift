import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation template.
    final class RevocationTemplateView {
        var code: String
        var labelText: String
        var procedureCodeText: String
        var country: String
        var dosageMg: String
        var startsAt: String
        var margin: String
        var categoryText: String
        var durationMinutes: String
        var capacityText: String
        var statusLabel: String

        init(code: String, labelText: String, procedureCodeText: String, country: String, dosageMg: String, startsAt: String, margin: String, categoryText: String, durationMinutes: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.procedureCodeText = procedureCodeText
            self.country = country
            self.dosageMg = dosageMg
            self.startsAt = startsAt
            self.margin = margin
            self.categoryText = categoryText
            self.durationMinutes = durationMinutes
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationTemplateView(_ item: RevocationTemplate) -> RevocationTemplateView {
        return RevocationTemplateView(
            code: item.code,
            labelText: item.label,
            procedureCodeText: item.procedureCode,
            country: item.country,
            dosageMg: String(format: "%.2f", item.dosageMg),
            startsAt: String(item.startsAt),
            margin: String(format: "%.2f", item.margin),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            durationMinutes: String(item.durationMinutes),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationTemplateViews(_ items: [RevocationTemplate]) -> [RevocationTemplateView] {
        var views: [RevocationTemplateView] = []
        for item in items {
            views.append(toRevocationTemplateView(item))
        }
        return views
    }

    static func sumRevocationTemplateView(_ view: RevocationTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDosageMg + Double(parsedStartsAt) + parsedMargin
    }
}
