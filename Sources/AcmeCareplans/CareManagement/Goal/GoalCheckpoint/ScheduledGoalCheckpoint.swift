import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled goal checkpoint is in its life cycle.
    enum ScheduledGoalCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled goal checkpoint. Its code is unique within a tenant.
    final class ScheduledGoalCheckpoint {
        var code: String
        var title: String
        var description: String
        var retries: Int
        var sequence: Int
        var rate: Double
        var budget: Double
        var ratio: Double
        var timezone: String
        var notes: String
        var visitMinutes: Int
        var status: ScheduledGoalCheckpointStatus

        init(code: String, title: String, description: String, retries: Int, sequence: Int, rate: Double, budget: Double, ratio: Double, timezone: String, notes: String, visitMinutes: Int, status: ScheduledGoalCheckpointStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.retries = retries
            self.sequence = sequence
            self.rate = rate
            self.budget = budget
            self.ratio = ratio
            self.timezone = timezone
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledGoalCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledGoalCheckpointStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledGoalCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled goal checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return (ratio * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledGoalCheckpoint {
            return ScheduledGoalCheckpoint(
                code: code,
                title: title,
                description: description,
                retries: retries,
                sequence: sequence,
                rate: rate,
                budget: budget,
                ratio: ratio,
                timezone: timezone,
                notes: notes,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled goal checkpoint in status new.
    static func newScheduledGoalCheckpoint(_ code: String, title: String) -> ScheduledGoalCheckpoint {
        return ScheduledGoalCheckpoint(
            code: code,
            title: title,
            description: "",
            retries: 0,
            sequence: 0,
            rate: 0.0,
            budget: 0.0,
            ratio: 0.0,
            timezone: "",
            notes: "",
            visitMinutes: 0,
            status: ScheduledGoalCheckpointStatus.new
        )
    }
}
