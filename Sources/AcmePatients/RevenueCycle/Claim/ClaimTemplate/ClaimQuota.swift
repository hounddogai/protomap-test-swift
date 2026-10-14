import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim quota is in its life cycle.
    enum ClaimQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One claim quota, with what the planners need to act on it.
    final class ClaimQuota {
        var code: String
        var title: String
        var quantity: Int
        var description: String
        var maximum: Double
        var status: ClaimQuotaStatus

        init(code: String, title: String, quantity: Int, description: String, maximum: Double, status: ClaimQuotaStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.description = description
            self.maximum = maximum
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

        func canMoveTo(_ next: ClaimQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClaimQuotaStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ClaimQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return (Double(quantity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> ClaimQuota {
            return ClaimQuota(
                code: code,
                title: title,
                quantity: quantity,
                description: description,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a claim quota in status planned.
    static func newClaimQuota(_ code: String, title: String) -> ClaimQuota {
        return ClaimQuota(
            code: code,
            title: title,
            quantity: 0,
            description: "",
            maximum: 0.0,
            status: ClaimQuotaStatus.planned
        )
    }
}
