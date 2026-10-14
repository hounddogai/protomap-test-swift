import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary cycle.
    final class FormularyCycleView {
        var code: String
        var title: String
        var patientRef: String
        var floorValue: String
        var weight: String
        var description: String
        var minimumText: String
        var clinicianIDText: String
        var maximumText: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, patientRef: String, floorValue: String, weight: String, description: String, minimumText: String, clinicianIDText: String, maximumText: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.weight = weight
            self.description = description
            self.minimumText = minimumText
            self.clinicianIDText = clinicianIDText
            self.maximumText = maximumText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyCycleView(_ item: FormularyCycle) -> FormularyCycleView {
        return FormularyCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 40),
            patientRef: item.patientRef,
            floorValue: String(format: "%.2f", item.floorValue),
            weight: String(format: "%.2f", item.weight),
            description: item.description,
            minimumText: String(format: "%.2f", item.minimum),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            maximumText: String(format: "%.2f", item.maximum),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyCycleViews(_ items: [FormularyCycle]) -> [FormularyCycleView] {
        var views: [FormularyCycleView] = []
        for item in items {
            views.append(toFormularyCycleView(item))
        }
        return views
    }

    static func sumFormularyCycleView(_ view: FormularyCycleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedFloorValue + parsedWeight + parsedMinimum
    }
}
