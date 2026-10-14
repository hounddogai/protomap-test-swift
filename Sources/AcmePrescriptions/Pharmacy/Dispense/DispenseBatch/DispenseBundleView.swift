import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense bundle.
    final class DispenseBundleView {
        var code: String
        var titleText: String
        var margin: String
        var active: String
        var floorValue: String
        var procedureCodeText: String
        var contactEmailText: String
        var durationMinutes: String
        var priority: String
        var copay: String
        var patientRef: String
        var statusLabel: String

        init(code: String, titleText: String, margin: String, active: String, floorValue: String, procedureCodeText: String, contactEmailText: String, durationMinutes: String, priority: String, copay: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.margin = margin
            self.active = active
            self.floorValue = floorValue
            self.procedureCodeText = procedureCodeText
            self.contactEmailText = contactEmailText
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.copay = copay
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseBundleView(_ item: DispenseBundle) -> DispenseBundleView {
        return DispenseBundleView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            margin: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCodeText: item.procedureCode,
            contactEmailText: item.contactEmail,
            durationMinutes: String(item.durationMinutes),
            priority: String(item.priority),
            copay: String(format: "%.2f", item.copay),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseBundleViews(_ items: [DispenseBundle]) -> [DispenseBundleView] {
        var views: [DispenseBundleView] = []
        for item in items {
            views.append(toDispenseBundleView(item))
        }
        return views
    }

    static func sumDispenseBundleView(_ view: DispenseBundleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMargin + parsedFloorValue + Double(parsedDurationMinutes)
    }
}
