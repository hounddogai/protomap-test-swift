import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift template is in its life cycle.
    enum GlobalShiftTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global shift template as the shift team keeps it.
    final class GlobalShiftTemplate {
        var code: String
        var label: String
        var specialty: String
        var externalRef: String
        var minimum: Double
        var diagnosisCode: String
        var status: GlobalShiftTemplateStatus

        init(code: String, label: String, specialty: String, externalRef: String, minimum: Double, diagnosisCode: String, status: GlobalShiftTemplateStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.externalRef = externalRef
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalShiftTemplateStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalShiftTemplateStatus.inProgress
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
                return next == GlobalShiftTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalShiftTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> GlobalShiftTemplate {
            return GlobalShiftTemplate(
                code: code,
                label: label,
                specialty: specialty,
                externalRef: externalRef,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global shift template in status planned.
    static func newGlobalShiftTemplate(_ code: String, label: String) -> GlobalShiftTemplate {
        return GlobalShiftTemplate(
            code: code,
            label: label,
            specialty: "",
            externalRef: "",
            minimum: 0.0,
            diagnosisCode: "",
            status: GlobalShiftTemplateStatus.planned
        )
    }
}
