import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling priority reservation.
    final class RollingPriorityReservationView {
        var codeText: String
        var name: String
        var batchSize: String
        var archived: String
        var capacity: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, batchSize: String, archived: String, capacity: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.batchSize = batchSize
            self.archived = archived
            self.capacity = capacity
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPriorityReservationView(_ item: RollingPriorityReservation) -> RollingPriorityReservationView {
        return RollingPriorityReservationView(
            codeText: item.code,
            name: item.name,
            batchSize: String(item.batchSize),
            archived: "\(item.archived)",
            capacity: String(item.capacity),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPriorityReservationViews(_ items: [RollingPriorityReservation]) -> [RollingPriorityReservationView] {
        var views: [RollingPriorityReservationView] = []
        for item in items {
            views.append(toRollingPriorityReservationView(item))
        }
        return views
    }

    static func sumRollingPriorityReservationView(_ view: RollingPriorityReservationView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCapacity) + Double(parsedVisitMinutes)
    }
}
