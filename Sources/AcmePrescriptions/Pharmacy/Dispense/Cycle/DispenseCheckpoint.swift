import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense checkpoint is in its life cycle.
    enum DispenseCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A dispense checkpoint as the dispense team keeps it.
    final class DispenseCheckpoint {
        var code: String
        var title: String
        var durationMinutes: Int
        var diagnosisCode: String
        var label: String
        var maximum: Double
        var status: DispenseCheckpointStatus

        init(code: String, title: String, durationMinutes: Int, diagnosisCode: String, label: String, maximum: Double, status: DispenseCheckpointStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.label = label
            self.maximum = maximum
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

        func canMoveTo(_ next: DispenseCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DispenseCheckpointStatus.reopened || next == DispenseCheckpointStatus.archived
            case .resolved:
                return next == DispenseCheckpointStatus.reopened
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

        func moveTo(_ next: DispenseCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> DispenseCheckpoint {
            return DispenseCheckpoint(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                label: label,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense checkpoint in status open.
    static func newDispenseCheckpoint(_ code: String, title: String) -> DispenseCheckpoint {
        return DispenseCheckpoint(
            code: code,
            title: title,
            durationMinutes: 0,
            diagnosisCode: "",
            label: "",
            maximum: 0.0,
            status: DispenseCheckpointStatus.`open`
        )
    }
}
