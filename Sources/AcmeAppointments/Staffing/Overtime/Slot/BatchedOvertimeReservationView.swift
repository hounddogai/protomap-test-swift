import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched overtime reservation.
    final class BatchedOvertimeReservationView {
        var code: String
        var title: String
        var nameText: String
        var patientRefText: String
        var capacity: String
        var limit: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, nameText: String, patientRefText: String, capacity: String, limit: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.nameText = nameText
            self.patientRefText = patientRefText
            self.capacity = capacity
            self.limit = limit
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOvertimeReservationView(_ item: BatchedOvertimeReservation) -> BatchedOvertimeReservationView {
        return BatchedOvertimeReservationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            capacity: String(item.capacity),
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOvertimeReservationViews(_ items: [BatchedOvertimeReservation]) -> [BatchedOvertimeReservationView] {
        var views: [BatchedOvertimeReservationView] = []
        for item in items {
            views.append(toBatchedOvertimeReservationView(item))
        }
        return views
    }

    static func sumBatchedOvertimeReservationView(_ view: BatchedOvertimeReservationView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedCapacity) + Double(parsedLimit) + Double(parsedEndsAt)
    }
}
