import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution policy is in its life cycle.
    enum SubstitutionPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a substitution policy and its current status.
    final class SubstitutionPolicy {
        var code: String
        var title: String
        var specialty: String
        var externalRef: String
        var score: Double
        var diagnosisCode: String
        var quantity: Int
        var copay: Double
        var status: SubstitutionPolicyStatus

        init(code: String, title: String, specialty: String, externalRef: String, score: Double, diagnosisCode: String, quantity: Int, copay: Double, status: SubstitutionPolicyStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.externalRef = externalRef
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.copay = copay
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

        func canMoveTo(_ next: SubstitutionPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SubstitutionPolicyStatus.rejected || next == SubstitutionPolicyStatus.withdrawn
            case .rejected:
                return next == SubstitutionPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((copay - score) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionPolicy {
            return SubstitutionPolicy(
                code: code,
                title: title,
                specialty: specialty,
                externalRef: externalRef,
                score: score,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution policy in status proposed.
    static func newSubstitutionPolicy(_ code: String, title: String) -> SubstitutionPolicy {
        return SubstitutionPolicy(
            code: code,
            title: title,
            specialty: "",
            externalRef: "",
            score: 0.0,
            diagnosisCode: "",
            quantity: 0,
            copay: 0.0,
            status: SubstitutionPolicyStatus.proposed
        )
    }
}
