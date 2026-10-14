import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched eligibility variance is in its life cycle.
    enum BatchedEligibilityVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched eligibility variance, with what the planners need to act on it.
    final class BatchedEligibilityVariance {
        var code: String
        var name: String
        var timezone: String
        var updatedAt: Int
        var startsAt: Int
        var attempts: Int
        var label: String
        var encounterID: String
        var dosageMg: Double
        var status: BatchedEligibilityVarianceStatus

        init(code: String, name: String, timezone: String, updatedAt: Int, startsAt: Int, attempts: Int, label: String, encounterID: String, dosageMg: Double, status: BatchedEligibilityVarianceStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.attempts = attempts
            self.label = label
            self.encounterID = encounterID
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedEligibilityVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedEligibilityVarianceStatus.published || next == BatchedEligibilityVarianceStatus.retired
            case .validated:
                return next == BatchedEligibilityVarianceStatus.published || next == BatchedEligibilityVarianceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BatchedEligibilityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched eligibility variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return (Double(startsAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> BatchedEligibilityVariance {
            return BatchedEligibilityVariance(
                code: code,
                name: name,
                timezone: timezone,
                updatedAt: updatedAt,
                startsAt: startsAt,
                attempts: attempts,
                label: label,
                encounterID: encounterID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched eligibility variance in status created.
    static func newBatchedEligibilityVariance(_ code: String, name: String) -> BatchedEligibilityVariance {
        return BatchedEligibilityVariance(
            code: code,
            name: name,
            timezone: "",
            updatedAt: 0,
            startsAt: 0,
            attempts: 0,
            label: "",
            encounterID: "",
            dosageMg: 0.0,
            status: BatchedEligibilityVarianceStatus.created
        )
    }
}
