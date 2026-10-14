import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive accession budget.
    final class AdaptiveAccessionBudgetView {
        var codeText: String
        var name: String
        var procedureCode: String
        var specialty: String
        var maximum: String
        var notesText: String
        var weightText: String
        var retriesText: String
        var country: String
        var copay: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, specialty: String, maximum: String, notesText: String, weightText: String, retriesText: String, country: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.maximum = maximum
            self.notesText = notesText
            self.weightText = weightText
            self.retriesText = retriesText
            self.country = country
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAccessionBudgetView(_ item: AdaptiveAccessionBudget) -> AdaptiveAccessionBudgetView {
        return AdaptiveAccessionBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            procedureCode: item.procedureCode,
            specialty: item.specialty,
            maximum: String(format: "%.2f", item.maximum),
            notesText: item.notes,
            weightText: String(format: "%.2f", item.weight),
            retriesText: String(item.retries),
            country: Kit.Text.truncate(item.country, limit: 64),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAccessionBudgetViews(_ items: [AdaptiveAccessionBudget]) -> [AdaptiveAccessionBudgetView] {
        var views: [AdaptiveAccessionBudgetView] = []
        for item in items {
            views.append(toAdaptiveAccessionBudgetView(item))
        }
        return views
    }

    static func sumAdaptiveAccessionBudgetView(_ view: AdaptiveAccessionBudgetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMaximum + parsedWeight + Double(parsedRetries)
    }
}
