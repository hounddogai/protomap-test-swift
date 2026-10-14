import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped shift exception.
    final class CappedShiftExceptionView {
        var codeText: String
        var name: String
        var labelText: String
        var clinicianIDText: String
        var notes: String
        var attemptsText: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, name: String, labelText: String, clinicianIDText: String, notes: String, attemptsText: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.labelText = labelText
            self.clinicianIDText = clinicianIDText
            self.notes = notes
            self.attemptsText = attemptsText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toCappedShiftExceptionView(_ item: CappedShiftException) -> CappedShiftExceptionView {
        return CappedShiftExceptionView(
            codeText: item.code,
            name: item.name,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            clinicianIDText: item.clinicianID,
            notes: item.notes,
            attemptsText: String(item.attempts),
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedShiftExceptionViews(_ items: [CappedShiftException]) -> [CappedShiftExceptionView] {
        var views: [CappedShiftExceptionView] = []
        for item in items {
            views.append(toCappedShiftExceptionView(item))
        }
        return views
    }

    static func sumCappedShiftExceptionView(_ view: CappedShiftExceptionView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
