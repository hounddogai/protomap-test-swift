import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority schedule is in its life cycle.
    enum PriorityScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A priority schedule as the priority team keeps it.
    final class PrioritySchedule {
        var code: String
        var label: String
        var sequence: Int
        var graceDays: Int
        var ownerID: String
        var status: PriorityScheduleStatus

        init(code: String, label: String, sequence: Int, graceDays: Int, ownerID: String, status: PriorityScheduleStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.graceDays = graceDays
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityScheduleStatus) -> Bool {
            switch status {
            case .created:
                return next == PriorityScheduleStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrioritySchedule {
            return PrioritySchedule(
                code: code,
                label: label,
                sequence: sequence,
                graceDays: graceDays,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a priority schedule in status created.
    static func newPrioritySchedule(_ code: String, label: String) -> PrioritySchedule {
        return PrioritySchedule(
            code: code,
            label: label,
            sequence: 0,
            graceDays: 0,
            ownerID: "",
            status: PriorityScheduleStatus.created
        )
    }
}
