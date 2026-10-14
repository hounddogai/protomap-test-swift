import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global eligibility plan is in its life cycle.
    enum GlobalEligibilityPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global eligibility plan, with what the planners need to act on it.
    final class GlobalEligibilityPlan {
        var code: String
        var label: String
        var bed: String
        var ceiling: Double
        var country: String
        var status: GlobalEligibilityPlanStatus

        init(code: String, label: String, bed: String, ceiling: Double, country: String, status: GlobalEligibilityPlanStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.ceiling = ceiling
            self.country = country
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

        func canMoveTo(_ next: GlobalEligibilityPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalEligibilityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global eligibility plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global eligibility plan") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> GlobalEligibilityPlan {
            return GlobalEligibilityPlan(
                code: code,
                label: label,
                bed: bed,
                ceiling: ceiling,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global eligibility plan in status requested.
    static func newGlobalEligibilityPlan(_ code: String, label: String) -> GlobalEligibilityPlan {
        return GlobalEligibilityPlan(
            code: code,
            label: label,
            bed: "",
            ceiling: 0.0,
            country: "",
            status: GlobalEligibilityPlanStatus.requested
        )
    }
}
