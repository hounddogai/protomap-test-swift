import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier cycle is in its life cycle.
    enum CourierCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A courier cycle as the courier team keeps it.
    final class CourierCycle {
        var code: String
        var name: String
        var attempts: Int
        var graceDays: Int
        var retries: Int
        var status: CourierCycleStatus

        init(code: String, name: String, attempts: Int, graceDays: Int, retries: Int, status: CourierCycleStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.graceDays = graceDays
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierCycleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CourierCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(retries) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CourierCycle {
            return CourierCycle(
                code: code,
                name: name,
                attempts: attempts,
                graceDays: graceDays,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier cycle in status open.
    static func newCourierCycle(_ code: String, name: String) -> CourierCycle {
        return CourierCycle(
            code: code,
            name: name,
            attempts: 0,
            graceDays: 0,
            retries: 0,
            status: CourierCycleStatus.`open`
        )
    }
}
