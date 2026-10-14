import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study assignment.
    final class StudyAssignmentView {
        var code: String
        var nameText: String
        var batchSize: String
        var source: String
        var floorValue: String
        var discount: String
        var copay: String
        var descriptionText: String
        var minimum: String
        var statusLabel: String

        init(code: String, nameText: String, batchSize: String, source: String, floorValue: String, discount: String, copay: String, descriptionText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.batchSize = batchSize
            self.source = source
            self.floorValue = floorValue
            self.discount = discount
            self.copay = copay
            self.descriptionText = descriptionText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toStudyAssignmentView(_ item: StudyAssignment) -> StudyAssignmentView {
        return StudyAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            batchSize: String(item.batchSize),
            source: Kit.Text.truncate(item.source, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            discount: String(format: "%.2f", item.discount),
            copay: String(format: "%.2f", item.copay),
            descriptionText: item.description,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyAssignmentViews(_ items: [StudyAssignment]) -> [StudyAssignmentView] {
        var views: [StudyAssignmentView] = []
        for item in items {
            views.append(toStudyAssignmentView(item))
        }
        return views
    }

    static func sumStudyAssignmentView(_ view: StudyAssignmentView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedBatchSize) + parsedFloorValue + parsedDiscount
    }
}
