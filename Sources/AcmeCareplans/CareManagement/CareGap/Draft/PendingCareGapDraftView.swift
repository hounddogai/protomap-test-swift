import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending care gap draft.
    final class PendingCareGapDraftView {
        var code: String
        var name: String
        var weight: String
        var capacity: String
        var batchSizeText: String
        var payer: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, name: String, weight: String, capacity: String, batchSizeText: String, payer: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.capacity = capacity
            self.batchSizeText = batchSizeText
            self.payer = payer
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCareGapDraftView(_ item: PendingCareGapDraft) -> PendingCareGapDraftView {
        return PendingCareGapDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            capacity: String(item.capacity),
            batchSizeText: String(item.batchSize),
            payer: item.payer,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCareGapDraftViews(_ items: [PendingCareGapDraft]) -> [PendingCareGapDraftView] {
        var views: [PendingCareGapDraftView] = []
        for item in items {
            views.append(toPendingCareGapDraftView(item))
        }
        return views
    }

    static func sumPendingCareGapDraftView(_ view: PendingCareGapDraftView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedWeight + Double(parsedCapacity) + Double(parsedBatchSize)
    }
}
