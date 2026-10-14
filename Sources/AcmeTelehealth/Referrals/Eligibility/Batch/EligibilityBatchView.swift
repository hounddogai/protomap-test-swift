import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility batch.
    final class EligibilityBatchView {
        var code: String
        var title: String
        var minimum: String
        var refills: String
        var bed: String
        var countryText: String
        var sourceText: String
        var timezoneText: String
        var marginText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, refills: String, bed: String, countryText: String, sourceText: String, timezoneText: String, marginText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.refills = refills
            self.bed = bed
            self.countryText = countryText
            self.sourceText = sourceText
            self.timezoneText = timezoneText
            self.marginText = marginText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityBatchView(_ item: EligibilityBatch) -> EligibilityBatchView {
        return EligibilityBatchView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            refills: String(item.refills),
            bed: item.bed,
            countryText: Kit.Text.truncate(item.country, limit: 40),
            sourceText: item.source,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            marginText: String(format: "%.2f", item.margin),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityBatchViews(_ items: [EligibilityBatch]) -> [EligibilityBatchView] {
        var views: [EligibilityBatchView] = []
        for item in items {
            views.append(toEligibilityBatchView(item))
        }
        return views
    }

    static func sumEligibilityBatchView(_ view: EligibilityBatchView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMinimum + Double(parsedRefills) + parsedMargin
    }
}
