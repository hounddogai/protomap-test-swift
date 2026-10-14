import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary assignment is in its life cycle.
    enum ManualFormularyAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual formulary assignment, with what the planners need to act on it.
    final class ManualFormularyAssignment {
        var code: String
        var label: String
        var minimum: Double
        var visitMinutes: Int
        var active: Bool
        var threshold: Double
        var summary: String
        var specialty: String
        var status: ManualFormularyAssignmentStatus

        init(code: String, label: String, minimum: Double, visitMinutes: Int, active: Bool, threshold: Double, summary: String, specialty: String, status: ManualFormularyAssignmentStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.visitMinutes = visitMinutes
            self.active = active
            self.threshold = threshold
            self.summary = summary
            self.specialty = specialty
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

        func canMoveTo(_ next: ManualFormularyAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualFormularyAssignmentStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ManualFormularyAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((minimum - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyAssignment {
            return ManualFormularyAssignment(
                code: code,
                label: label,
                minimum: minimum,
                visitMinutes: visitMinutes,
                active: active,
                threshold: threshold,
                summary: summary,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual formulary assignment in status proposed.
    static func newManualFormularyAssignment(_ code: String, label: String) -> ManualFormularyAssignment {
        return ManualFormularyAssignment(
            code: code,
            label: label,
            minimum: 0.0,
            visitMinutes: 0,
            active: false,
            threshold: 0.0,
            summary: "",
            specialty: "",
            status: ManualFormularyAssignmentStatus.proposed
        )
    }
}
