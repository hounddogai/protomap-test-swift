import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending eligibility variance is in its life cycle.
    enum PendingEligibilityVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending eligibility variance, with what the planners need to act on it.
    final class PendingEligibilityVariance {
        var code: String
        var title: String
        var channel: String
        var locale: String
        var priority: Int
        var payer: String
        var amount: Double
        var refills: Int
        var attempts: Int
        var updatedAt: Int
        var unit: String
        var status: PendingEligibilityVarianceStatus

        init(code: String, title: String, channel: String, locale: String, priority: Int, payer: String, amount: Double, refills: Int, attempts: Int, updatedAt: Int, unit: String, status: PendingEligibilityVarianceStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.locale = locale
            self.priority = priority
            self.payer = payer
            self.amount = amount
            self.refills = refills
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.unit = unit
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

        func canMoveTo(_ next: PendingEligibilityVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingEligibilityVarianceStatus.scheduled || next == PendingEligibilityVarianceStatus.completed
            case .scheduled:
                return next == PendingEligibilityVarianceStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingEligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((Double(refills) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PendingEligibilityVariance {
            return PendingEligibilityVariance(
                code: code,
                title: title,
                channel: channel,
                locale: locale,
                priority: priority,
                payer: payer,
                amount: amount,
                refills: refills,
                attempts: attempts,
                updatedAt: updatedAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending eligibility variance in status planned.
    static func newPendingEligibilityVariance(_ code: String, title: String) -> PendingEligibilityVariance {
        return PendingEligibilityVariance(
            code: code,
            title: title,
            channel: "",
            locale: "",
            priority: 0,
            payer: "",
            amount: 0.0,
            refills: 0,
            attempts: 0,
            updatedAt: 0,
            unit: "",
            status: PendingEligibilityVarianceStatus.planned
        )
    }
}
