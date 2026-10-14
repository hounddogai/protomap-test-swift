import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen forecast.
    final class SpecimenForecastView {
        var code: String
        var label: String
        var weightText: String
        var sequenceText: String
        var dosageMgText: String
        var title: String
        var score: String
        var quantity: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, weightText: String, sequenceText: String, dosageMgText: String, title: String, score: String, quantity: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weightText = weightText
            self.sequenceText = sequenceText
            self.dosageMgText = dosageMgText
            self.title = title
            self.score = score
            self.quantity = quantity
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenForecastView(_ item: SpecimenForecast) -> SpecimenForecastView {
        return SpecimenForecastView(
            code: item.code,
            label: item.label,
            weightText: String(format: "%.2f", item.weight),
            sequenceText: String(item.sequence),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            title: item.title,
            score: String(format: "%.2f", item.score),
            quantity: String(item.quantity),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenForecastViews(_ items: [SpecimenForecast]) -> [SpecimenForecastView] {
        var views: [SpecimenForecastView] = []
        for item in items {
            views.append(toSpecimenForecastView(item))
        }
        return views
    }

    static func sumSpecimenForecastView(_ view: SpecimenForecastView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedWeight + Double(parsedSequence) + parsedDosageMg
    }
}
