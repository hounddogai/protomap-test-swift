import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched care protocol reservation.
    final class BatchedCareProtocolReservationView {
        var codeText: String
        var nameText: String
        var updatedAt: String
        var specialtyText: String
        var reviewer: String
        var weight: String
        var amount: String
        var visible: String
        var statusLabel: String

        init(codeText: String, nameText: String, updatedAt: String, specialtyText: String, reviewer: String, weight: String, amount: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.updatedAt = updatedAt
            self.specialtyText = specialtyText
            self.reviewer = reviewer
            self.weight = weight
            self.amount = amount
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareProtocolReservationView(_ item: BatchedCareProtocolReservation) -> BatchedCareProtocolReservationView {
        return BatchedCareProtocolReservationView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            updatedAt: String(item.updatedAt),
            specialtyText: item.specialty,
            reviewer: item.reviewer,
            weight: String(format: "%.2f", item.weight),
            amount: String(format: "%.2f", item.amount),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareProtocolReservationViews(_ items: [BatchedCareProtocolReservation]) -> [BatchedCareProtocolReservationView] {
        var views: [BatchedCareProtocolReservationView] = []
        for item in items {
            views.append(toBatchedCareProtocolReservationView(item))
        }
        return views
    }

    static func sumBatchedCareProtocolReservationView(_ view: BatchedCareProtocolReservationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedUpdatedAt) + parsedWeight + parsedAmount
    }
}
