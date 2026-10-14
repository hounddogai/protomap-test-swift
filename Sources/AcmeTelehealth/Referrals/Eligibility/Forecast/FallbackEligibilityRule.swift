import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility rule is in its life cycle.
    enum FallbackEligibilityRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback eligibility rule. Its code is unique within a tenant.
    final class FallbackEligibilityRule {
        var code: String
        var title: String
        var clinicianID: String
        var score: Double
        var ownerID: String
        var graceDays: Int
        var version: Int
        var status: FallbackEligibilityRuleStatus

        init(code: String, title: String, clinicianID: String, score: Double, ownerID: String, graceDays: Int, version: Int, status: FallbackEligibilityRuleStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.score = score
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.version = version
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

        func canMoveTo(_ next: FallbackEligibilityRuleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackEligibilityRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackEligibilityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("fallback eligibility rule") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(graceDays) - score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackEligibilityRule {
            return FallbackEligibilityRule(
                code: code,
                title: title,
                clinicianID: clinicianID,
                score: score,
                ownerID: ownerID,
                graceDays: graceDays,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback eligibility rule in status planned.
    static func newFallbackEligibilityRule(_ code: String, title: String) -> FallbackEligibilityRule {
        return FallbackEligibilityRule(
            code: code,
            title: title,
            clinicianID: "",
            score: 0.0,
            ownerID: "",
            graceDays: 0,
            version: 0,
            status: FallbackEligibilityRuleStatus.planned
        )
    }
}
