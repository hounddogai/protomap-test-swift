import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility digest is in its life cycle.
    enum FallbackEligibilityDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback eligibility digest, with what the planners need to act on it.
    final class FallbackEligibilityDigest {
        var code: String
        var label: String
        var priority: Int
        var checksum: String
        var diagnosisCode: String
        var description: String
        var status: FallbackEligibilityDigestStatus

        init(code: String, label: String, priority: Int, checksum: String, diagnosisCode: String, description: String, status: FallbackEligibilityDigestStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.description = description
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

        func canMoveTo(_ next: FallbackEligibilityDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackEligibilityDigestStatus.inReview || next == FallbackEligibilityDigestStatus.reopened
            case .inReview:
                return next == FallbackEligibilityDigestStatus.archived
            case .resolved:
                return next == FallbackEligibilityDigestStatus.reopened || next == FallbackEligibilityDigestStatus.archived
            case .reopened:
                return next == FallbackEligibilityDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackEligibilityDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> FallbackEligibilityDigest {
            return FallbackEligibilityDigest(
                code: code,
                label: label,
                priority: priority,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback eligibility digest in status open.
    static func newFallbackEligibilityDigest(_ code: String, label: String) -> FallbackEligibilityDigest {
        return FallbackEligibilityDigest(
            code: code,
            label: label,
            priority: 0,
            checksum: "",
            diagnosisCode: "",
            description: "",
            status: FallbackEligibilityDigestStatus.`open`
        )
    }
}
