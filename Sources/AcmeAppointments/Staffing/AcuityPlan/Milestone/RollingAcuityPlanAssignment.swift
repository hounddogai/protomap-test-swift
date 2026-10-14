import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling acuity plan assignment is in its life cycle.
    enum RollingAcuityPlanAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling acuity plan assignment and its current status.
    final class RollingAcuityPlanAssignment {
        var code: String
        var name: String
        var sequence: Int
        var durationMinutes: Int
        var description: String
        var threshold: Double
        var label: String
        var retries: Int
        var status: RollingAcuityPlanAssignmentStatus

        init(code: String, name: String, sequence: Int, durationMinutes: Int, description: String, threshold: Double, label: String, retries: Int, status: RollingAcuityPlanAssignmentStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.description = description
            self.threshold = threshold
            self.label = label
            self.retries = retries
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

        func canMoveTo(_ next: RollingAcuityPlanAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingAcuityPlanAssignmentStatus.inProgress || next == RollingAcuityPlanAssignmentStatus.completed
            case .scheduled:
                return next == RollingAcuityPlanAssignmentStatus.completed || next == RollingAcuityPlanAssignmentStatus.cancelled
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

        func moveTo(_ next: RollingAcuityPlanAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling acuity plan assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (Double(retries) * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingAcuityPlanAssignment {
            return RollingAcuityPlanAssignment(
                code: code,
                name: name,
                sequence: sequence,
                durationMinutes: durationMinutes,
                description: description,
                threshold: threshold,
                label: label,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling acuity plan assignment in status planned.
    static func newRollingAcuityPlanAssignment(_ code: String, name: String) -> RollingAcuityPlanAssignment {
        return RollingAcuityPlanAssignment(
            code: code,
            name: name,
            sequence: 0,
            durationMinutes: 0,
            description: "",
            threshold: 0.0,
            label: "",
            retries: 0,
            status: RollingAcuityPlanAssignmentStatus.planned
        )
    }
}
