import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority audit is in its life cycle.
    enum AdaptivePriorityAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive priority audit. Its code is unique within a tenant.
    final class AdaptivePriorityAudit {
        var code: String
        var name: String
        var currency: String
        var attempts: Int
        var budget: Double
        var retries: Int
        var rate: Double
        var maximum: Double
        var channel: String
        var status: AdaptivePriorityAuditStatus

        init(code: String, name: String, currency: String, attempts: Int, budget: Double, retries: Int, rate: Double, maximum: Double, channel: String, status: AdaptivePriorityAuditStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.attempts = attempts
            self.budget = budget
            self.retries = retries
            self.rate = rate
            self.maximum = maximum
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptivePriorityAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptivePriorityAuditStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptivePriorityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (Double(attempts) * rate * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePriorityAudit {
            return AdaptivePriorityAudit(
                code: code,
                name: name,
                currency: currency,
                attempts: attempts,
                budget: budget,
                retries: retries,
                rate: rate,
                maximum: maximum,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive priority audit in status requested.
    static func newAdaptivePriorityAudit(_ code: String, name: String) -> AdaptivePriorityAudit {
        return AdaptivePriorityAudit(
            code: code,
            name: name,
            currency: "",
            attempts: 0,
            budget: 0.0,
            retries: 0,
            rate: 0.0,
            maximum: 0.0,
            channel: "",
            status: AdaptivePriorityAuditStatus.requested
        )
    }
}
