import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary draft is in its life cycle.
    enum FormularyDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a formulary draft and its current status.
    final class FormularyDraft {
        var code: String
        var name: String
        var externalRef: String
        var timezone: String
        var patientRef: String
        var diagnosisCode: String
        var acuity: Int
        var score: Double
        var status: FormularyDraftStatus

        init(code: String, name: String, externalRef: String, timezone: String, patientRef: String, diagnosisCode: String, acuity: Int, score: Double, status: FormularyDraftStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.timezone = timezone
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.score = score
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

        func canMoveTo(_ next: FormularyDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FormularyDraftStatus.resolved || next == FormularyDraftStatus.archived
            case .resolved:
                return next == FormularyDraftStatus.reopened || next == FormularyDraftStatus.archived
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

        func moveTo(_ next: FormularyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("formulary draft") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(acuity) + score) * 100).rounded() / 100
        }

        func copyValue() -> FormularyDraft {
            return FormularyDraft(
                code: code,
                name: name,
                externalRef: externalRef,
                timezone: timezone,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                acuity: acuity,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary draft in status open.
    static func newFormularyDraft(_ code: String, name: String) -> FormularyDraft {
        return FormularyDraft(
            code: code,
            name: name,
            externalRef: "",
            timezone: "",
            patientRef: "",
            diagnosisCode: "",
            acuity: 0,
            score: 0.0,
            status: FormularyDraftStatus.`open`
        )
    }
}
