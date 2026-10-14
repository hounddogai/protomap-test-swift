import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task reservation is in its life cycle.
    enum TaskReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One task reservation, with what the planners need to act on it.
    final class TaskReservation {
        var code: String
        var title: String
        var dosageMg: Double
        var diagnosisCode: String
        var description: String
        var graceDays: Int
        var capacity: Int
        var region: String
        var channel: String
        var checksum: String
        var status: TaskReservationStatus

        init(code: String, title: String, dosageMg: Double, diagnosisCode: String, description: String, graceDays: Int, capacity: Int, region: String, channel: String, checksum: String, status: TaskReservationStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.graceDays = graceDays
            self.capacity = capacity
            self.region = region
            self.channel = channel
            self.checksum = checksum
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

        func canMoveTo(_ next: TaskReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TaskReservationStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TaskReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((Double(capacity) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TaskReservation {
            return TaskReservation(
                code: code,
                title: title,
                dosageMg: dosageMg,
                diagnosisCode: diagnosisCode,
                description: description,
                graceDays: graceDays,
                capacity: capacity,
                region: region,
                channel: channel,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a task reservation in status planned.
    static func newTaskReservation(_ code: String, title: String) -> TaskReservation {
        return TaskReservation(
            code: code,
            title: title,
            dosageMg: 0.0,
            diagnosisCode: "",
            description: "",
            graceDays: 0,
            capacity: 0,
            region: "",
            channel: "",
            checksum: "",
            status: TaskReservationStatus.planned
        )
    }
}
