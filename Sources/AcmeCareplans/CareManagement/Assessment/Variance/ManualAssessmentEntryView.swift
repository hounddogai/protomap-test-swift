import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual assessment entry.
    final class ManualAssessmentEntryView {
        var codeText: String
        var title: String
        var contactEmailText: String
        var quantity: String
        var summary: String
        var batchSize: String
        var visibleText: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmailText: String, quantity: String, summary: String, batchSize: String, visibleText: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmailText = contactEmailText
            self.quantity = quantity
            self.summary = summary
            self.batchSize = batchSize
            self.visibleText = visibleText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toManualAssessmentEntryView(_ item: ManualAssessmentEntry) -> ManualAssessmentEntryView {
        return ManualAssessmentEntryView(
            codeText: item.code,
            title: item.title,
            contactEmailText: item.contactEmail,
            quantity: String(item.quantity),
            summary: item.summary,
            batchSize: String(item.batchSize),
            visibleText: "\(item.visible)",
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAssessmentEntryViews(_ items: [ManualAssessmentEntry]) -> [ManualAssessmentEntryView] {
        var views: [ManualAssessmentEntryView] = []
        for item in items {
            views.append(toManualAssessmentEntryView(item))
        }
        return views
    }

    static func sumManualAssessmentEntryView(_ view: ManualAssessmentEntryView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize) + parsedMinimum
    }
}
