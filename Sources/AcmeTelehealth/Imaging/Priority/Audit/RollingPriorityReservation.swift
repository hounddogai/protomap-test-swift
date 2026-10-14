import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority reservation is in its life cycle.
    enum RollingPriorityReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling priority reservation. Its code is unique within a tenant.
    final class RollingPriorityReservation {
        var code: String
        var name: String
        var batchSize: Int
        var archived: Bool
        var capacity: Int
        var visitMinutes: Int
        var status: RollingPriorityReservationStatus

        init(code: String, name: String, batchSize: Int, archived: Bool, capacity: Int, visitMinutes: Int, status: RollingPriorityReservationStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.archived = archived
            self.capacity = capacity
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RollingPriorityReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingPriorityReservationStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RollingPriorityReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingPriorityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(capacity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingPriorityReservation {
            return RollingPriorityReservation(
                code: code,
                name: name,
                batchSize: batchSize,
                archived: archived,
                capacity: capacity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling priority reservation in status proposed.
    static func newRollingPriorityReservation(_ code: String, name: String) -> RollingPriorityReservation {
        return RollingPriorityReservation(
            code: code,
            name: name,
            batchSize: 0,
            archived: false,
            capacity: 0,
            visitMinutes: 0,
            status: RollingPriorityReservationStatus.proposed
        )
    }
}
