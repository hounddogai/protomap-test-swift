import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility plan is in its life cycle.
    enum FallbackEligibilityPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback eligibility plan. Its code is unique within a tenant.
    final class FallbackEligibilityPlan {
        var code: String
        var title: String
        var payer: String
        var label: String
        var timezone: String
        var procedureCode: String
        var checksum: String
        var score: Double
        var archived: Bool
        var status: FallbackEligibilityPlanStatus

        init(code: String, title: String, payer: String, label: String, timezone: String, procedureCode: String, checksum: String, score: Double, archived: Bool, status: FallbackEligibilityPlanStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.label = label
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.score = score
            self.archived = archived
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

        func canMoveTo(_ next: FallbackEligibilityPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackEligibilityPlanStatus.revoked || next == FallbackEligibilityPlanStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackEligibilityPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackEligibilityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback eligibility plan") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> FallbackEligibilityPlan {
            return FallbackEligibilityPlan(
                code: code,
                title: title,
                payer: payer,
                label: label,
                timezone: timezone,
                procedureCode: procedureCode,
                checksum: checksum,
                score: score,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback eligibility plan in status requested.
    static func newFallbackEligibilityPlan(_ code: String, title: String) -> FallbackEligibilityPlan {
        return FallbackEligibilityPlan(
            code: code,
            title: title,
            payer: "",
            label: "",
            timezone: "",
            procedureCode: "",
            checksum: "",
            score: 0.0,
            archived: false,
            status: FallbackEligibilityPlanStatus.requested
        )
    }
}
