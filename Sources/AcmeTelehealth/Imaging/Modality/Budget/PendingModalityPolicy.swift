import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending modality policy is in its life cycle.
    enum PendingModalityPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a pending modality policy and its current status.
    final class PendingModalityPolicy {
        var code: String
        var title: String
        var minimum: Double
        var cost: Double
        var timezone: String
        var attempts: Int
        var ratio: Double
        var threshold: Double
        var status: PendingModalityPolicyStatus

        init(code: String, title: String, minimum: Double, cost: Double, timezone: String, attempts: Int, ratio: Double, threshold: Double, status: PendingModalityPolicyStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.cost = cost
            self.timezone = timezone
            self.attempts = attempts
            self.ratio = ratio
            self.threshold = threshold
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

        func canMoveTo(_ next: PendingModalityPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingModalityPolicyStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingModalityPolicyStatus.reopened || next == PendingModalityPolicyStatus.archived
            case .reopened:
                return next == PendingModalityPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingModalityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending modality policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending modality policy") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((minimum - ratio) * 100).rounded() / 100
        }

        func copyValue() -> PendingModalityPolicy {
            return PendingModalityPolicy(
                code: code,
                title: title,
                minimum: minimum,
                cost: cost,
                timezone: timezone,
                attempts: attempts,
                ratio: ratio,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending modality policy in status open.
    static func newPendingModalityPolicy(_ code: String, title: String) -> PendingModalityPolicy {
        return PendingModalityPolicy(
            code: code,
            title: title,
            minimum: 0.0,
            cost: 0.0,
            timezone: "",
            attempts: 0,
            ratio: 0.0,
            threshold: 0.0,
            status: PendingModalityPolicyStatus.`open`
        )
    }
}
