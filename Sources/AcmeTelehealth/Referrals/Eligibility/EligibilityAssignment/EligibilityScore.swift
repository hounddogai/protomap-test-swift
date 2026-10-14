import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility score is in its life cycle.
    enum EligibilityScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One eligibility score, with what the planners need to act on it.
    final class EligibilityScore {
        var code: String
        var label: String
        var budget: Double
        var phone: String
        var copay: Double
        var retries: Int
        var endsAt: Int
        var amount: Double
        var approved: Bool
        var patientRef: String
        var status: EligibilityScoreStatus

        init(code: String, label: String, budget: Double, phone: String, copay: Double, retries: Int, endsAt: Int, amount: Double, approved: Bool, patientRef: String, status: EligibilityScoreStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.phone = phone
            self.copay = copay
            self.retries = retries
            self.endsAt = endsAt
            self.amount = amount
            self.approved = approved
            self.patientRef = patientRef
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

        func canMoveTo(_ next: EligibilityScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == EligibilityScoreStatus.rejected || next == EligibilityScoreStatus.withdrawn
            case .rejected:
                return next == EligibilityScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (copay * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityScore {
            return EligibilityScore(
                code: code,
                label: label,
                budget: budget,
                phone: phone,
                copay: copay,
                retries: retries,
                endsAt: endsAt,
                amount: amount,
                approved: approved,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility score in status proposed.
    static func newEligibilityScore(_ code: String, label: String) -> EligibilityScore {
        return EligibilityScore(
            code: code,
            label: label,
            budget: 0.0,
            phone: "",
            copay: 0.0,
            retries: 0,
            endsAt: 0,
            amount: 0.0,
            approved: false,
            patientRef: "",
            status: EligibilityScoreStatus.proposed
        )
    }
}
