import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness assignment.
    final class WitnessAssignmentView {
        var code: String
        var title: String
        var categoryText: String
        var procedureCode: String
        var minimum: String
        var floorValue: String
        var threshold: String
        var dosageMg: String
        var graceDays: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, title: String, categoryText: String, procedureCode: String, minimum: String, floorValue: String, threshold: String, dosageMg: String, graceDays: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.categoryText = categoryText
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.floorValue = floorValue
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessAssignmentView(_ item: WitnessAssignment) -> WitnessAssignmentView {
        return WitnessAssignmentView(
            code: item.code,
            title: item.title,
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            procedureCode: item.procedureCode,
            minimum: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            threshold: String(format: "%.2f", item.threshold),
            dosageMg: String(format: "%.2f", item.dosageMg),
            graceDays: String(item.graceDays),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessAssignmentViews(_ items: [WitnessAssignment]) -> [WitnessAssignmentView] {
        var views: [WitnessAssignmentView] = []
        for item in items {
            views.append(toWitnessAssignmentView(item))
        }
        return views
    }

    static func sumWitnessAssignmentView(_ view: WitnessAssignmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMinimum + parsedFloorValue + parsedThreshold
    }
}
