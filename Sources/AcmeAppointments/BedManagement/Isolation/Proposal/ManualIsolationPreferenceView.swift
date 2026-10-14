import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual isolation preference.
    final class ManualIsolationPreferenceView {
        var code: String
        var name: String
        var notes: String
        var currency: String
        var dosageMg: String
        var country: String
        var procedureCode: String
        var score: String
        var startsAtText: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, notes: String, currency: String, dosageMg: String, country: String, procedureCode: String, score: String, startsAtText: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notes = notes
            self.currency = currency
            self.dosageMg = dosageMg
            self.country = country
            self.procedureCode = procedureCode
            self.score = score
            self.startsAtText = startsAtText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toManualIsolationPreferenceView(_ item: ManualIsolationPreference) -> ManualIsolationPreferenceView {
        return ManualIsolationPreferenceView(
            code: item.code,
            name: item.name,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            currency: Kit.Text.truncate(item.currency, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            country: Kit.Text.truncate(item.country, limit: 120),
            procedureCode: item.procedureCode,
            score: String(format: "%.2f", item.score),
            startsAtText: String(item.startsAt),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualIsolationPreferenceViews(_ items: [ManualIsolationPreference]) -> [ManualIsolationPreferenceView] {
        var views: [ManualIsolationPreferenceView] = []
        for item in items {
            views.append(toManualIsolationPreferenceView(item))
        }
        return views
    }

    static func sumManualIsolationPreferenceView(_ view: ManualIsolationPreferenceView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDosageMg + parsedScore + Double(parsedStartsAt)
    }
}
