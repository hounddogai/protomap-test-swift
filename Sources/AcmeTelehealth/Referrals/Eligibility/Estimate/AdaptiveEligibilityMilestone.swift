import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive eligibility milestone is in its life cycle.
    enum AdaptiveEligibilityMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive eligibility milestone as the eligibility team keeps it.
    final class AdaptiveEligibilityMilestone {
        var code: String
        var title: String
        var allergy: String
        var discount: Double
        var source: String
        var status: AdaptiveEligibilityMilestoneStatus

        init(code: String, title: String, allergy: String, discount: Double, source: String, status: AdaptiveEligibilityMilestoneStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.discount = discount
            self.source = source
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

        func canMoveTo(_ next: AdaptiveEligibilityMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveEligibilityMilestoneStatus.archived
            case .inReview:
                return next == AdaptiveEligibilityMilestoneStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveEligibilityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive eligibility milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> AdaptiveEligibilityMilestone {
            return AdaptiveEligibilityMilestone(
                code: code,
                title: title,
                allergy: allergy,
                discount: discount,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive eligibility milestone in status open.
    static func newAdaptiveEligibilityMilestone(_ code: String, title: String) -> AdaptiveEligibilityMilestone {
        return AdaptiveEligibilityMilestone(
            code: code,
            title: title,
            allergy: "",
            discount: 0.0,
            source: "",
            status: AdaptiveEligibilityMilestoneStatus.`open`
        )
    }
}
