import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary float pool budget is in its life cycle.
    enum PrimaryFloatPoolBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary float pool budget, with what the planners need to act on it.
    final class PrimaryFloatPoolBudget {
        var code: String
        var name: String
        var graceDays: Int
        var priority: Int
        var channel: String
        var score: Double
        var status: PrimaryFloatPoolBudgetStatus

        init(code: String, name: String, graceDays: Int, priority: Int, channel: String, score: Double, status: PrimaryFloatPoolBudgetStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.priority = priority
            self.channel = channel
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

        func canMoveTo(_ next: PrimaryFloatPoolBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryFloatPoolBudgetStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryFloatPoolBudgetStatus.draining || next == PrimaryFloatPoolBudgetStatus.stopped
            case .draining:
                return next == PrimaryFloatPoolBudgetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryFloatPoolBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary float pool budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary float pool budget") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((score + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFloatPoolBudget {
            return PrimaryFloatPoolBudget(
                code: code,
                name: name,
                graceDays: graceDays,
                priority: priority,
                channel: channel,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary float pool budget in status idle.
    static func newPrimaryFloatPoolBudget(_ code: String, name: String) -> PrimaryFloatPoolBudget {
        return PrimaryFloatPoolBudget(
            code: code,
            name: name,
            graceDays: 0,
            priority: 0,
            channel: "",
            score: 0.0,
            status: PrimaryFloatPoolBudgetStatus.idle
        )
    }
}
