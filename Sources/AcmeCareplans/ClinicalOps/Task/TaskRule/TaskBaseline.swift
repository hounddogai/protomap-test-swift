import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task baseline is in its life cycle.
    enum TaskBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One task baseline, with what the planners need to act on it.
    final class TaskBaseline {
        var code: String
        var title: String
        var score: Double
        var dosageMg: Double
        var cost: Double
        var endsAt: Int
        var sequence: Int
        var retries: Int
        var reviewer: String
        var weight: Double
        var startsAt: Int
        var status: TaskBaselineStatus

        init(code: String, title: String, score: Double, dosageMg: Double, cost: Double, endsAt: Int, sequence: Int, retries: Int, reviewer: String, weight: Double, startsAt: Int, status: TaskBaselineStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.dosageMg = dosageMg
            self.cost = cost
            self.endsAt = endsAt
            self.sequence = sequence
            self.retries = retries
            self.reviewer = reviewer
            self.weight = weight
            self.startsAt = startsAt
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

        func canMoveTo(_ next: TaskBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == TaskBaselineStatus.scheduled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TaskBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("task baseline") \(code)"
        }

        func weightedVolume() -> Double {
            return (score * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> TaskBaseline {
            return TaskBaseline(
                code: code,
                title: title,
                score: score,
                dosageMg: dosageMg,
                cost: cost,
                endsAt: endsAt,
                sequence: sequence,
                retries: retries,
                reviewer: reviewer,
                weight: weight,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a task baseline in status planned.
    static func newTaskBaseline(_ code: String, title: String) -> TaskBaseline {
        return TaskBaseline(
            code: code,
            title: title,
            score: 0.0,
            dosageMg: 0.0,
            cost: 0.0,
            endsAt: 0,
            sequence: 0,
            retries: 0,
            reviewer: "",
            weight: 0.0,
            startsAt: 0,
            status: TaskBaselineStatus.planned
        )
    }
}
