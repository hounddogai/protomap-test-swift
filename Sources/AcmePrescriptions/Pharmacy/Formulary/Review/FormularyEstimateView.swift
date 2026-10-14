import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary estimate.
    final class FormularyEstimateView {
        var codeText: String
        var titleText: String
        var graceDays: String
        var archived: String
        var refills: String
        var ceiling: String
        var locale: String
        var encounterIDText: String
        var startsAtText: String
        var statusLabel: String

        init(codeText: String, titleText: String, graceDays: String, archived: String, refills: String, ceiling: String, locale: String, encounterIDText: String, startsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.graceDays = graceDays
            self.archived = archived
            self.refills = refills
            self.ceiling = ceiling
            self.locale = locale
            self.encounterIDText = encounterIDText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyEstimateView(_ item: FormularyEstimate) -> FormularyEstimateView {
        return FormularyEstimateView(
            codeText: item.code,
            titleText: item.title,
            graceDays: String(item.graceDays),
            archived: "\(item.archived)",
            refills: String(item.refills),
            ceiling: String(format: "%.2f", item.ceiling),
            locale: item.locale,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyEstimateViews(_ items: [FormularyEstimate]) -> [FormularyEstimateView] {
        var views: [FormularyEstimateView] = []
        for item in items {
            views.append(toFormularyEstimateView(item))
        }
        return views
    }

    static func sumFormularyEstimateView(_ view: FormularyEstimateView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRefills) + parsedCeiling
    }
}
