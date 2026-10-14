import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation estimate is in its life cycle.
    enum RevocationEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A revocation estimate. Its code is unique within a tenant.
    final class RevocationEstimate {
        var code: String
        var label: String
        var threshold: Double
        var ratio: Double
        var refills: Int
        var active: Bool
        var name: String
        var rate: Double
        var attempts: Int
        var graceDays: Int
        var status: RevocationEstimateStatus

        init(code: String, label: String, threshold: Double, ratio: Double, refills: Int, active: Bool, name: String, rate: Double, attempts: Int, graceDays: Int, status: RevocationEstimateStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.ratio = ratio
            self.refills = refills
            self.active = active
            self.name = name
            self.rate = rate
            self.attempts = attempts
            self.graceDays = graceDays
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

        func canMoveTo(_ next: RevocationEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == RevocationEstimateStatus.scheduled || next == RevocationEstimateStatus.completed
            case .scheduled:
                return next == RevocationEstimateStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RevocationEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation estimate") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationEstimate {
            return RevocationEstimate(
                code: code,
                label: label,
                threshold: threshold,
                ratio: ratio,
                refills: refills,
                active: active,
                name: name,
                rate: rate,
                attempts: attempts,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation estimate in status planned.
    static func newRevocationEstimate(_ code: String, label: String) -> RevocationEstimate {
        return RevocationEstimate(
            code: code,
            label: label,
            threshold: 0.0,
            ratio: 0.0,
            refills: 0,
            active: false,
            name: "",
            rate: 0.0,
            attempts: 0,
            graceDays: 0,
            status: RevocationEstimateStatus.planned
        )
    }
}
