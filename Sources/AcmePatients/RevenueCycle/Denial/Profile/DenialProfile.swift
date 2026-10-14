import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial profile is in its life cycle.
    enum DenialProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A denial profile. Its code is unique within a tenant.
    final class DenialProfile {
        var code: String
        var label: String
        var diagnosisCode: String
        var budget: Double
        var sequence: Int
        var dosageMg: Double
        var status: DenialProfileStatus

        init(code: String, label: String, diagnosisCode: String, budget: Double, sequence: Int, dosageMg: Double, status: DenialProfileStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.sequence = sequence
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: DenialProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialProfileStatus.approved || next == DenialProfileStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DenialProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("denial profile") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DenialProfile {
            return DenialProfile(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                budget: budget,
                sequence: sequence,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a denial profile in status proposed.
    static func newDenialProfile(_ code: String, label: String) -> DenialProfile {
        return DenialProfile(
            code: code,
            label: label,
            diagnosisCode: "",
            budget: 0.0,
            sequence: 0,
            dosageMg: 0.0,
            status: DenialProfileStatus.proposed
        )
    }
}
