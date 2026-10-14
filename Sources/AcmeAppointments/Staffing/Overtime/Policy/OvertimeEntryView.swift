import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime entry.
    final class OvertimeEntryView {
        var code: String
        var name: String
        var procedureCodeText: String
        var attempts: String
        var allergy: String
        var locale: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, attempts: String, allergy: String, locale: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.attempts = attempts
            self.allergy = allergy
            self.locale = locale
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeEntryView(_ item: OvertimeEntry) -> OvertimeEntryView {
        return OvertimeEntryView(
            code: item.code,
            name: item.name,
            procedureCodeText: item.procedureCode,
            attempts: String(item.attempts),
            allergy: item.allergy,
            locale: item.locale,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeEntryViews(_ items: [OvertimeEntry]) -> [OvertimeEntryView] {
        var views: [OvertimeEntryView] = []
        for item in items {
            views.append(toOvertimeEntryView(item))
        }
        return views
    }

    static func sumOvertimeEntryView(_ view: OvertimeEntryView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity)
    }
}
