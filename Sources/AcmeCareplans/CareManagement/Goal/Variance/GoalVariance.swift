import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal variance is in its life cycle.
    enum GoalVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A goal variance as the goal team keeps it.
    final class GoalVariance {
        var code: String
        var label: String
        var createdAt: Int
        var channel: String
        var title: String
        var status: GoalVarianceStatus

        init(code: String, label: String, createdAt: Int, channel: String, title: String, status: GoalVarianceStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.channel = channel
            self.title = title
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

        func canMoveTo(_ next: GoalVarianceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GoalVarianceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> GoalVariance {
            return GoalVariance(
                code: code,
                label: label,
                createdAt: createdAt,
                channel: channel,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a goal variance in status idle.
    static func newGoalVariance(_ code: String, label: String) -> GoalVariance {
        return GoalVariance(
            code: code,
            label: label,
            createdAt: 0,
            channel: "",
            title: "",
            status: GoalVarianceStatus.idle
        )
    }
}
