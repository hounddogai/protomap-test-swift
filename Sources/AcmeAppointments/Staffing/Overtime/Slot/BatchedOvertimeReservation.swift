import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime reservation is in its life cycle.
    enum BatchedOvertimeReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched overtime reservation, with what the planners need to act on it.
    final class BatchedOvertimeReservation {
        var code: String
        var title: String
        var name: String
        var patientRef: String
        var capacity: Int
        var limit: Int
        var endsAt: Int
        var status: BatchedOvertimeReservationStatus

        init(code: String, title: String, name: String, patientRef: String, capacity: Int, limit: Int, endsAt: Int, status: BatchedOvertimeReservationStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.patientRef = patientRef
            self.capacity = capacity
            self.limit = limit
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedOvertimeReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedOvertimeReservationStatus.approved || next == BatchedOvertimeReservationStatus.rejected
            case .approved:
                return next == BatchedOvertimeReservationStatus.rejected
            case .rejected:
                return next == BatchedOvertimeReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOvertimeReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched overtime reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(capacity) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimeReservation {
            return BatchedOvertimeReservation(
                code: code,
                title: title,
                name: name,
                patientRef: patientRef,
                capacity: capacity,
                limit: limit,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched overtime reservation in status proposed.
    static func newBatchedOvertimeReservation(_ code: String, title: String) -> BatchedOvertimeReservation {
        return BatchedOvertimeReservation(
            code: code,
            title: title,
            name: "",
            patientRef: "",
            capacity: 0,
            limit: 0,
            endsAt: 0,
            status: BatchedOvertimeReservationStatus.proposed
        )
    }
}
