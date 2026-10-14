import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment threshold is in its life cycle.
    enum AssessmentThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One assessment threshold, with what the planners need to act on it.
    final class AssessmentThreshold {
        var code: String
        var label: String
        var allergy: String
        var dosageMg: Double
        var rate: Double
        var specialty: String
        var status: AssessmentThresholdStatus

        init(code: String, label: String, allergy: String, dosageMg: Double, rate: Double, specialty: String, status: AssessmentThresholdStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.rate = rate
            self.specialty = specialty
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

        func canMoveTo(_ next: AssessmentThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AssessmentThresholdStatus.completed
            case .completed:
                return next == AssessmentThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return (dosageMg * rate * 100).rounded() / 100
        }

        func copyValue() -> AssessmentThreshold {
            return AssessmentThreshold(
                code: code,
                label: label,
                allergy: allergy,
                dosageMg: dosageMg,
                rate: rate,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment threshold in status planned.
    static func newAssessmentThreshold(_ code: String, label: String) -> AssessmentThreshold {
        return AssessmentThreshold(
            code: code,
            label: label,
            allergy: "",
            dosageMg: 0.0,
            rate: 0.0,
            specialty: "",
            status: AssessmentThresholdStatus.planned
        )
    }
}
