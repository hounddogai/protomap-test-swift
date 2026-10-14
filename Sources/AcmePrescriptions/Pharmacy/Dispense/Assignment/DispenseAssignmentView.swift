import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense assignment.
    final class DispenseAssignmentView {
        var codeText: String
        var labelText: String
        var refills: String
        var facilityText: String
        var durationMinutesText: String
        var version: String
        var acuity: String
        var allergy: String
        var locale: String
        var statusLabel: String

        init(codeText: String, labelText: String, refills: String, facilityText: String, durationMinutesText: String, version: String, acuity: String, allergy: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.refills = refills
            self.facilityText = facilityText
            self.durationMinutesText = durationMinutesText
            self.version = version
            self.acuity = acuity
            self.allergy = allergy
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseAssignmentView(_ item: DispenseAssignment) -> DispenseAssignmentView {
        return DispenseAssignmentView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            refills: String(item.refills),
            facilityText: item.facility,
            durationMinutesText: String(item.durationMinutes),
            version: String(item.version),
            acuity: String(item.acuity),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseAssignmentViews(_ items: [DispenseAssignment]) -> [DispenseAssignmentView] {
        var views: [DispenseAssignmentView] = []
        for item in items {
            views.append(toDispenseAssignmentView(item))
        }
        return views
    }

    static func sumDispenseAssignmentView(_ view: DispenseAssignmentView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRefills) + Double(parsedDurationMinutes) + Double(parsedVersion)
    }
}
