import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched modality mapping.
    final class BatchedModalityMappingView {
        var code: String
        var nameText: String
        var quantity: String
        var durationMinutes: String
        var visitMinutesText: String
        var patientRef: String
        var limit: String
        var acuity: String
        var encounterID: String
        var statusLabel: String

        init(code: String, nameText: String, quantity: String, durationMinutes: String, visitMinutesText: String, patientRef: String, limit: String, acuity: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.visitMinutesText = visitMinutesText
            self.patientRef = patientRef
            self.limit = limit
            self.acuity = acuity
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedModalityMappingView(_ item: BatchedModalityMapping) -> BatchedModalityMappingView {
        return BatchedModalityMappingView(
            code: item.code,
            nameText: item.name,
            quantity: String(item.quantity),
            durationMinutes: String(item.durationMinutes),
            visitMinutesText: String(item.visitMinutes),
            patientRef: item.patientRef,
            limit: String(item.limit),
            acuity: String(item.acuity),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedModalityMappingViews(_ items: [BatchedModalityMapping]) -> [BatchedModalityMappingView] {
        var views: [BatchedModalityMappingView] = []
        for item in items {
            views.append(toBatchedModalityMappingView(item))
        }
        return views
    }

    static func sumBatchedModalityMappingView(_ view: BatchedModalityMappingView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedDurationMinutes) + Double(parsedVisitMinutes)
    }
}
