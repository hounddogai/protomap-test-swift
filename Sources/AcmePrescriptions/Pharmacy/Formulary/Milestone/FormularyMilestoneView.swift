import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary milestone.
    final class FormularyMilestoneView {
        var codeText: String
        var labelText: String
        var unit: String
        var minimum: String
        var floorValue: String
        var visitMinutesText: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, labelText: String, unit: String, minimum: String, floorValue: String, visitMinutesText: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.unit = unit
            self.minimum = minimum
            self.floorValue = floorValue
            self.visitMinutesText = visitMinutesText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyMilestoneView(_ item: FormularyMilestone) -> FormularyMilestoneView {
        return FormularyMilestoneView(
            codeText: item.code,
            labelText: item.label,
            unit: item.unit,
            minimum: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            visitMinutesText: String(item.visitMinutes),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyMilestoneViews(_ items: [FormularyMilestone]) -> [FormularyMilestoneView] {
        var views: [FormularyMilestoneView] = []
        for item in items {
            views.append(toFormularyMilestoneView(item))
        }
        return views
    }

    static func sumFormularyMilestoneView(_ view: FormularyMilestoneView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMinimum + parsedFloorValue + Double(parsedVisitMinutes)
    }
}
