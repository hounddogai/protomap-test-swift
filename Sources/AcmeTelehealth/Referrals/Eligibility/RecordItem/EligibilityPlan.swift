import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility plan is in its life cycle.
    enum EligibilityPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One eligibility plan, with what the planners need to act on it.
    final class EligibilityPlan {
        var code: String
        var title: String
        var discount: Double
        var patientRef: String
        var attempts: Int
        var amount: Double
        var externalRef: String
        var clinicianID: String
        var status: EligibilityPlanStatus

        init(code: String, title: String, discount: Double, patientRef: String, attempts: Int, amount: Double, externalRef: String, clinicianID: String, status: EligibilityPlanStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.patientRef = patientRef
            self.attempts = attempts
            self.amount = amount
            self.externalRef = externalRef
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: EligibilityPlanStatus) -> Bool {
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
                case .inProgress, .completed:
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
                switch next {
                case .cancelled:
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

        func moveTo(_ next: EligibilityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("eligibility plan") \(code)"
        }

        func adjustedVolume() -> Double {
            return (amount * discount * 100).rounded() / 100
        }

        func copyValue() -> EligibilityPlan {
            return EligibilityPlan(
                code: code,
                title: title,
                discount: discount,
                patientRef: patientRef,
                attempts: attempts,
                amount: amount,
                externalRef: externalRef,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility plan in status planned.
    static func newEligibilityPlan(_ code: String, title: String) -> EligibilityPlan {
        return EligibilityPlan(
            code: code,
            title: title,
            discount: 0.0,
            patientRef: "",
            attempts: 0,
            amount: 0.0,
            externalRef: "",
            clinicianID: "",
            status: EligibilityPlanStatus.planned
        )
    }
}
