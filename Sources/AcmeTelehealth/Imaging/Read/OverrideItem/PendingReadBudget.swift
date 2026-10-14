import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read budget is in its life cycle.
    enum PendingReadBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending read budget, with what the planners need to act on it.
    final class PendingReadBudget {
        var code: String
        var name: String
        var channel: String
        var copay: Double
        var source: String
        var status: PendingReadBudgetStatus

        init(code: String, name: String, channel: String, copay: Double, source: String, status: PendingReadBudgetStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.copay = copay
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingReadBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PendingReadBudgetStatus.rejected || next == PendingReadBudgetStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingReadBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending read budget") \(code)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> PendingReadBudget {
            return PendingReadBudget(
                code: code,
                name: name,
                channel: channel,
                copay: copay,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending read budget in status proposed.
    static func newPendingReadBudget(_ code: String, name: String) -> PendingReadBudget {
        return PendingReadBudget(
            code: code,
            name: name,
            channel: "",
            copay: 0.0,
            source: "",
            status: PendingReadBudgetStatus.proposed
        )
    }
}
