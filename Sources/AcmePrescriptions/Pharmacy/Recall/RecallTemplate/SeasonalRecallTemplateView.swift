import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal recall template.
    final class SeasonalRecallTemplateView {
        var code: String
        var title: String
        var dosageMg: String
        var ownerID: String
        var description: String
        var segment: String
        var statusLabel: String

        init(code: String, title: String, dosageMg: String, ownerID: String, description: String, segment: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.description = description
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRecallTemplateView(_ item: SeasonalRecallTemplate) -> SeasonalRecallTemplateView {
        return SeasonalRecallTemplateView(
            code: item.code,
            title: item.title,
            dosageMg: String(format: "%.2f", item.dosageMg),
            ownerID: item.ownerID,
            description: item.description,
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRecallTemplateViews(_ items: [SeasonalRecallTemplate]) -> [SeasonalRecallTemplateView] {
        var views: [SeasonalRecallTemplateView] = []
        for item in items {
            views.append(toSeasonalRecallTemplateView(item))
        }
        return views
    }

    static func sumSeasonalRecallTemplateView(_ view: SeasonalRecallTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
