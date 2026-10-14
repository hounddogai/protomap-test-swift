import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling isolation assignment is in its life cycle.
    enum RollingIsolationAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling isolation assignment, with what the planners need to act on it.
    final class RollingIsolationAssignment {
        var code: String
        var name: String
        var ownerID: String
        var dosageMg: Double
        var score: Double
        var status: RollingIsolationAssignmentStatus

        init(code: String, name: String, ownerID: String, dosageMg: Double, score: Double, status: RollingIsolationAssignmentStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.score = score
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

        func canMoveTo(_ next: RollingIsolationAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingIsolationAssignmentStatus.scheduled || next == RollingIsolationAssignmentStatus.inProgress
            case .scheduled:
                return next == RollingIsolationAssignmentStatus.inProgress || next == RollingIsolationAssignmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingIsolationAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingIsolationAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling isolation assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return (dosageMg * score * 100).rounded() / 100
        }

        func copyValue() -> RollingIsolationAssignment {
            return RollingIsolationAssignment(
                code: code,
                name: name,
                ownerID: ownerID,
                dosageMg: dosageMg,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling isolation assignment in status planned.
    static func newRollingIsolationAssignment(_ code: String, name: String) -> RollingIsolationAssignment {
        return RollingIsolationAssignment(
            code: code,
            name: name,
            ownerID: "",
            dosageMg: 0.0,
            score: 0.0,
            status: RollingIsolationAssignmentStatus.planned
        )
    }
}
