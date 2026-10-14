import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive outreach entry.
    final class AdaptiveOutreachEntryView {
        var code: String
        var titleText: String
        var durationMinutesText: String
        var dosageMg: String
        var locale: String
        var procedureCode: String
        var sourceText: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, durationMinutesText: String, dosageMg: String, locale: String, procedureCode: String, sourceText: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.durationMinutesText = durationMinutesText
            self.dosageMg = dosageMg
            self.locale = locale
            self.procedureCode = procedureCode
            self.sourceText = sourceText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOutreachEntryView(_ item: AdaptiveOutreachEntry) -> AdaptiveOutreachEntryView {
        return AdaptiveOutreachEntryView(
            code: item.code,
            titleText: item.title,
            durationMinutesText: String(item.durationMinutes),
            dosageMg: String(format: "%.2f", item.dosageMg),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            procedureCode: item.procedureCode,
            sourceText: item.source,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOutreachEntryViews(_ items: [AdaptiveOutreachEntry]) -> [AdaptiveOutreachEntryView] {
        var views: [AdaptiveOutreachEntryView] = []
        for item in items {
            views.append(toAdaptiveOutreachEntryView(item))
        }
        return views
    }

    static func sumAdaptiveOutreachEntryView(_ view: AdaptiveOutreachEntryView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedDurationMinutes) + parsedDosageMg + parsedWeight
    }
}
