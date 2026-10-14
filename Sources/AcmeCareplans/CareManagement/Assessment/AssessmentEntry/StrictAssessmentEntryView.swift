import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict assessment entry.
    final class StrictAssessmentEntryView {
        var code: String
        var labelText: String
        var externalRef: String
        var diagnosisCode: String
        var categoryText: String
        var source: String
        var amount: String
        var threshold: String
        var ward: String
        var graceDaysText: String
        var copay: String
        var statusLabel: String

        init(code: String, labelText: String, externalRef: String, diagnosisCode: String, categoryText: String, source: String, amount: String, threshold: String, ward: String, graceDaysText: String, copay: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.externalRef = externalRef
            self.diagnosisCode = diagnosisCode
            self.categoryText = categoryText
            self.source = source
            self.amount = amount
            self.threshold = threshold
            self.ward = ward
            self.graceDaysText = graceDaysText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAssessmentEntryView(_ item: StrictAssessmentEntry) -> StrictAssessmentEntryView {
        return StrictAssessmentEntryView(
            code: item.code,
            labelText: item.label,
            externalRef: item.externalRef,
            diagnosisCode: item.diagnosisCode,
            categoryText: item.category,
            source: item.source,
            amount: String(format: "%.2f", item.amount),
            threshold: String(format: "%.2f", item.threshold),
            ward: item.ward,
            graceDaysText: String(item.graceDays),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAssessmentEntryViews(_ items: [StrictAssessmentEntry]) -> [StrictAssessmentEntryView] {
        var views: [StrictAssessmentEntryView] = []
        for item in items {
            views.append(toStrictAssessmentEntryView(item))
        }
        return views
    }

    static func sumStrictAssessmentEntryView(_ view: StrictAssessmentEntryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedAmount + parsedThreshold + Double(parsedGraceDays)
    }
}
