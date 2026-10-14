import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy overtime manifest.
    final class LegacyOvertimeManifestView {
        var code: String
        var name: String
        var specialty: String
        var title: String
        var quantity: String
        var durationMinutesText: String
        var diagnosisCode: String
        var timezoneText: String
        var sequence: String
        var patientRef: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, title: String, quantity: String, durationMinutesText: String, diagnosisCode: String, timezoneText: String, sequence: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.title = title
            self.quantity = quantity
            self.durationMinutesText = durationMinutesText
            self.diagnosisCode = diagnosisCode
            self.timezoneText = timezoneText
            self.sequence = sequence
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOvertimeManifestView(_ item: LegacyOvertimeManifest) -> LegacyOvertimeManifestView {
        return LegacyOvertimeManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            title: item.title,
            quantity: String(item.quantity),
            durationMinutesText: String(item.durationMinutes),
            diagnosisCode: item.diagnosisCode,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            sequence: String(item.sequence),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOvertimeManifestViews(_ items: [LegacyOvertimeManifest]) -> [LegacyOvertimeManifestView] {
        var views: [LegacyOvertimeManifestView] = []
        for item in items {
            views.append(toLegacyOvertimeManifestView(item))
        }
        return views
    }

    static func sumLegacyOvertimeManifestView(_ view: LegacyOvertimeManifestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedQuantity) + Double(parsedDurationMinutes) + Double(parsedSequence)
    }
}
