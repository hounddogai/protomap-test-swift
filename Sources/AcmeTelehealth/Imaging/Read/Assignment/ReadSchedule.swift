import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read schedule is in its life cycle.
    enum ReadScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A read schedule as the read team keeps it.
    final class ReadSchedule {
        var code: String
        var name: String
        var facility: String
        var expiresAt: Int
        var copay: Double
        var discount: Double
        var ceiling: Double
        var status: ReadScheduleStatus

        init(code: String, name: String, facility: String, expiresAt: Int, copay: Double, discount: Double, ceiling: Double, status: ReadScheduleStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.expiresAt = expiresAt
            self.copay = copay
            self.discount = discount
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == ReadScheduleStatus.completed || next == ReadScheduleStatus.cancelled
            case .scheduled:
                return next == ReadScheduleStatus.inProgress || next == ReadScheduleStatus.cancelled
            case .inProgress:
                return next == ReadScheduleStatus.completed
            case .completed:
                return next == ReadScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (Double(expiresAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> ReadSchedule {
            return ReadSchedule(
                code: code,
                name: name,
                facility: facility,
                expiresAt: expiresAt,
                copay: copay,
                discount: discount,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a read schedule in status planned.
    static func newReadSchedule(_ code: String, name: String) -> ReadSchedule {
        return ReadSchedule(
            code: code,
            name: name,
            facility: "",
            expiresAt: 0,
            copay: 0.0,
            discount: 0.0,
            ceiling: 0.0,
            status: ReadScheduleStatus.planned
        )
    }
}
