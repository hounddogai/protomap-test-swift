import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen agreement is in its life cycle.
    enum SpecimenAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One specimen agreement, with what the planners need to act on it.
    final class SpecimenAgreement {
        var code: String
        var label: String
        var maximum: Double
        var specialty: String
        var procedureCode: String
        var status: SpecimenAgreementStatus

        init(code: String, label: String, maximum: Double, specialty: String, procedureCode: String, status: SpecimenAgreementStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SpecimenAgreementStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SpecimenAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> SpecimenAgreement {
            return SpecimenAgreement(
                code: code,
                label: label,
                maximum: maximum,
                specialty: specialty,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a specimen agreement in status draft.
    static func newSpecimenAgreement(_ code: String, label: String) -> SpecimenAgreement {
        return SpecimenAgreement(
            code: code,
            label: label,
            maximum: 0.0,
            specialty: "",
            procedureCode: "",
            status: SpecimenAgreementStatus.draft
        )
    }
}
