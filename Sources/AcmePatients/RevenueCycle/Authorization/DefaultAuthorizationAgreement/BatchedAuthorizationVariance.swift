import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization variance is in its life cycle.
    enum BatchedAuthorizationVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched authorization variance, with what the planners need to act on it.
    final class BatchedAuthorizationVariance {
        var code: String
        var label: String
        var encounterID: String
        var currency: String
        var summary: String
        var timezone: String
        var margin: Double
        var threshold: Double
        var status: BatchedAuthorizationVarianceStatus

        init(code: String, label: String, encounterID: String, currency: String, summary: String, timezone: String, margin: Double, threshold: Double, status: BatchedAuthorizationVarianceStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.currency = currency
            self.summary = summary
            self.timezone = timezone
            self.margin = margin
            self.threshold = threshold
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

        func canMoveTo(_ next: BatchedAuthorizationVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedAuthorizationVarianceStatus.approved
            case .approved:
                return next == BatchedAuthorizationVarianceStatus.rejected
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

        func moveTo(_ next: BatchedAuthorizationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return (threshold * margin * 100).rounded() / 100
        }

        func copyValue() -> BatchedAuthorizationVariance {
            return BatchedAuthorizationVariance(
                code: code,
                label: label,
                encounterID: encounterID,
                currency: currency,
                summary: summary,
                timezone: timezone,
                margin: margin,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched authorization variance in status proposed.
    static func newBatchedAuthorizationVariance(_ code: String, label: String) -> BatchedAuthorizationVariance {
        return BatchedAuthorizationVariance(
            code: code,
            label: label,
            encounterID: "",
            currency: "",
            summary: "",
            timezone: "",
            margin: 0.0,
            threshold: 0.0,
            status: BatchedAuthorizationVarianceStatus.proposed
        )
    }
}
