import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict task milestone is in its life cycle.
    enum StrictTaskMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One strict task milestone, with what the planners need to act on it.
    final class StrictTaskMilestone {
        var code: String
        var title: String
        var attempts: Int
        var checksum: String
        var score: Double
        var status: StrictTaskMilestoneStatus

        init(code: String, title: String, attempts: Int, checksum: String, score: Double, status: StrictTaskMilestoneStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.checksum = checksum
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictTaskMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictTaskMilestoneStatus.ready || next == StrictTaskMilestoneStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StrictTaskMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictTaskMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict task milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict task milestone") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(attempts) - score) * 100).rounded() / 100
        }

        func copyValue() -> StrictTaskMilestone {
            return StrictTaskMilestone(
                code: code,
                title: title,
                attempts: attempts,
                checksum: checksum,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict task milestone in status idle.
    static func newStrictTaskMilestone(_ code: String, title: String) -> StrictTaskMilestone {
        return StrictTaskMilestone(
            code: code,
            title: title,
            attempts: 0,
            checksum: "",
            score: 0.0,
            status: StrictTaskMilestoneStatus.idle
        )
    }
}
