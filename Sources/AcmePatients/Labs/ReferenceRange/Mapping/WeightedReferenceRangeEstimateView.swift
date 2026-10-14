import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted reference range estimate.
    final class WeightedReferenceRangeEstimateView {
        var codeText: String
        var name: String
        var titleText: String
        var archivedText: String
        var durationMinutesText: String
        var unit: String
        var discount: String
        var maximum: String
        var phone: String
        var procedureCodeText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, name: String, titleText: String, archivedText: String, durationMinutesText: String, unit: String, discount: String, maximum: String, phone: String, procedureCodeText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.titleText = titleText
            self.archivedText = archivedText
            self.durationMinutesText = durationMinutesText
            self.unit = unit
            self.discount = discount
            self.maximum = maximum
            self.phone = phone
            self.procedureCodeText = procedureCodeText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReferenceRangeEstimateView(_ item: WeightedReferenceRangeEstimate) -> WeightedReferenceRangeEstimateView {
        return WeightedReferenceRangeEstimateView(
            codeText: item.code,
            name: item.name,
            titleText: item.title,
            archivedText: "\(item.archived)",
            durationMinutesText: String(item.durationMinutes),
            unit: item.unit,
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            phone: item.phone,
            procedureCodeText: item.procedureCode,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReferenceRangeEstimateViews(_ items: [WeightedReferenceRangeEstimate]) -> [WeightedReferenceRangeEstimateView] {
        var views: [WeightedReferenceRangeEstimateView] = []
        for item in items {
            views.append(toWeightedReferenceRangeEstimateView(item))
        }
        return views
    }

    static func sumWeightedReferenceRangeEstimateView(_ view: WeightedReferenceRangeEstimateView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedDurationMinutes) + parsedDiscount + parsedMaximum
    }
}
