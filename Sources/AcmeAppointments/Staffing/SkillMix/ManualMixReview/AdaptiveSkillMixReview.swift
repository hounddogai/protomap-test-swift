import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive skill mix review is in its life cycle.
    enum AdaptiveSkillMixReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive skill mix review. Its code is unique within a tenant.
    final class AdaptiveSkillMixReview {
        var code: String
        var label: String
        var diagnosisCode: String
        var description: String
        var pinned: Bool
        var timezone: String
        var amount: Double
        var status: AdaptiveSkillMixReviewStatus

        init(code: String, label: String, diagnosisCode: String, description: String, pinned: Bool, timezone: String, amount: Double, status: AdaptiveSkillMixReviewStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.description = description
            self.pinned = pinned
            self.timezone = timezone
            self.amount = amount
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

        func canMoveTo(_ next: AdaptiveSkillMixReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveSkillMixReviewStatus.approved
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveSkillMixReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSkillMixReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive skill mix review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AdaptiveSkillMixReview {
            return AdaptiveSkillMixReview(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                description: description,
                pinned: pinned,
                timezone: timezone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive skill mix review in status proposed.
    static func newAdaptiveSkillMixReview(_ code: String, label: String) -> AdaptiveSkillMixReview {
        return AdaptiveSkillMixReview(
            code: code,
            label: label,
            diagnosisCode: "",
            description: "",
            pinned: false,
            timezone: "",
            amount: 0.0,
            status: AdaptiveSkillMixReviewStatus.proposed
        )
    }
}
