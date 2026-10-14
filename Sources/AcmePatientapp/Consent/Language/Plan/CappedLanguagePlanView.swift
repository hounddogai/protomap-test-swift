import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped language plan.
    final class CappedLanguagePlanView {
        var code: String
        var name: String
        var maximum: String
        var phoneText: String
        var attemptsText: String
        var reviewer: String
        var dosageMg: String
        var unit: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, maximum: String, phoneText: String, attemptsText: String, reviewer: String, dosageMg: String, unit: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.phoneText = phoneText
            self.attemptsText = attemptsText
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.unit = unit
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toCappedLanguagePlanView(_ item: CappedLanguagePlan) -> CappedLanguagePlanView {
        return CappedLanguagePlanView(
            code: item.code,
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            phoneText: item.phone,
            attemptsText: String(item.attempts),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedLanguagePlanViews(_ items: [CappedLanguagePlan]) -> [CappedLanguagePlanView] {
        var views: [CappedLanguagePlanView] = []
        for item in items {
            views.append(toCappedLanguagePlanView(item))
        }
        return views
    }

    static func sumCappedLanguagePlanView(_ view: CappedLanguagePlanView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMaximum + Double(parsedAttempts) + parsedDosageMg
    }
}
