import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge request is in its life cycle.
    enum ChargeRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A charge request as the charge team keeps it.
    final class ChargeRequest {
        var code: String
        var label: String
        var maximum: Double
        var timezone: String
        var limit: Int
        var channel: String
        var amount: Double
        var capacity: Int
        var attempts: Int
        var status: ChargeRequestStatus

        init(code: String, label: String, maximum: Double, timezone: String, limit: Int, channel: String, amount: Double, capacity: Int, attempts: Int, status: ChargeRequestStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.timezone = timezone
            self.limit = limit
            self.channel = channel
            self.amount = amount
            self.capacity = capacity
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ChargeRequestStatus.pending || next == ChargeRequestStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ChargeRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return (Double(attempts) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> ChargeRequest {
            return ChargeRequest(
                code: code,
                label: label,
                maximum: maximum,
                timezone: timezone,
                limit: limit,
                channel: channel,
                amount: amount,
                capacity: capacity,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a charge request in status draft.
    static func newChargeRequest(_ code: String, label: String) -> ChargeRequest {
        return ChargeRequest(
            code: code,
            label: label,
            maximum: 0.0,
            timezone: "",
            limit: 0,
            channel: "",
            amount: 0.0,
            capacity: 0,
            attempts: 0,
            status: ChargeRequestStatus.draft
        )
    }
}
