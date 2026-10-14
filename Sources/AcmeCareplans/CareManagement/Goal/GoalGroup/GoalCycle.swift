import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal cycle is in its life cycle.
    enum GoalCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A goal cycle as the goal team keeps it.
    final class GoalCycle {
        var code: String
        var name: String
        var priority: Int
        var minimum: Double
        var externalRef: String
        var ratio: Double
        var graceDays: Int
        var channel: String
        var discount: Double
        var status: GoalCycleStatus

        init(code: String, name: String, priority: Int, minimum: Double, externalRef: String, ratio: Double, graceDays: Int, channel: String, discount: Double, status: GoalCycleStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.minimum = minimum
            self.externalRef = externalRef
            self.ratio = ratio
            self.graceDays = graceDays
            self.channel = channel
            self.discount = discount
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

        func canMoveTo(_ next: GoalCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GoalCycleStatus.stopped
            case .ready:
                return next == GoalCycleStatus.draining || next == GoalCycleStatus.stopped
            case .draining:
                return next == GoalCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((ratio - discount) * 100).rounded() / 100
        }

        func copyValue() -> GoalCycle {
            return GoalCycle(
                code: code,
                name: name,
                priority: priority,
                minimum: minimum,
                externalRef: externalRef,
                ratio: ratio,
                graceDays: graceDays,
                channel: channel,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a goal cycle in status idle.
    static func newGoalCycle(_ code: String, name: String) -> GoalCycle {
        return GoalCycle(
            code: code,
            name: name,
            priority: 0,
            minimum: 0.0,
            externalRef: "",
            ratio: 0.0,
            graceDays: 0,
            channel: "",
            discount: 0.0,
            status: GoalCycleStatus.idle
        )
    }
}
