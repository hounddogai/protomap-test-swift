import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task cycle is in its life cycle.
    enum TaskCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a task cycle and its current status.
    final class TaskCycle {
        var code: String
        var name: String
        var source: String
        var attempts: Int
        var sequence: Int
        var ward: String
        var reviewer: String
        var startsAt: Int
        var copay: Double
        var segment: String
        var active: Bool
        var status: TaskCycleStatus

        init(code: String, name: String, source: String, attempts: Int, sequence: Int, ward: String, reviewer: String, startsAt: Int, copay: Double, segment: String, active: Bool, status: TaskCycleStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.attempts = attempts
            self.sequence = sequence
            self.ward = ward
            self.reviewer = reviewer
            self.startsAt = startsAt
            self.copay = copay
            self.segment = segment
            self.active = active
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

        func canMoveTo(_ next: TaskCycleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TaskCycleStatus.inProgress || next == TaskCycleStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TaskCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return (copay * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> TaskCycle {
            return TaskCycle(
                code: code,
                name: name,
                source: source,
                attempts: attempts,
                sequence: sequence,
                ward: ward,
                reviewer: reviewer,
                startsAt: startsAt,
                copay: copay,
                segment: segment,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a task cycle in status planned.
    static func newTaskCycle(_ code: String, name: String) -> TaskCycle {
        return TaskCycle(
            code: code,
            name: name,
            source: "",
            attempts: 0,
            sequence: 0,
            ward: "",
            reviewer: "",
            startsAt: 0,
            copay: 0.0,
            segment: "",
            active: false,
            status: TaskCycleStatus.planned
        )
    }
}
