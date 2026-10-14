import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy schedule is in its life cycle.
    enum ProxyScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a proxy schedule and its current status.
    final class ProxySchedule {
        var code: String
        var title: String
        var ceiling: Double
        var priority: Int
        var name: String
        var budget: Double
        var currency: String
        var status: ProxyScheduleStatus

        init(code: String, title: String, ceiling: Double, priority: Int, name: String, budget: Double, currency: String, status: ProxyScheduleStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.priority = priority
            self.name = name
            self.budget = budget
            self.currency = currency
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

        func canMoveTo(_ next: ProxyScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ProxyScheduleStatus.withdrawn
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

        func moveTo(_ next: ProxyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(priority) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ProxySchedule {
            return ProxySchedule(
                code: code,
                title: title,
                ceiling: ceiling,
                priority: priority,
                name: name,
                budget: budget,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy schedule in status proposed.
    static func newProxySchedule(_ code: String, title: String) -> ProxySchedule {
        return ProxySchedule(
            code: code,
            title: title,
            ceiling: 0.0,
            priority: 0,
            name: "",
            budget: 0.0,
            currency: "",
            status: ProxyScheduleStatus.proposed
        )
    }
}
