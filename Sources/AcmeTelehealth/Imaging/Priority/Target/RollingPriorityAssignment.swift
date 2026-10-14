import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority assignment is in its life cycle.
    enum RollingPriorityAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling priority assignment and its current status.
    final class RollingPriorityAssignment {
        var code: String
        var label: String
        var dosageMg: Double
        var allergy: String
        var bed: String
        var segment: String
        var revision: Int
        var floorValue: Double
        var threshold: Double
        var title: String
        var status: RollingPriorityAssignmentStatus

        init(code: String, label: String, dosageMg: Double, allergy: String, bed: String, segment: String, revision: Int, floorValue: Double, threshold: Double, title: String, status: RollingPriorityAssignmentStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.bed = bed
            self.segment = segment
            self.revision = revision
            self.floorValue = floorValue
            self.threshold = threshold
            self.title = title
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

        func canMoveTo(_ next: RollingPriorityAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingPriorityAssignmentStatus.inProgress || next == RollingPriorityAssignmentStatus.completed
            case .inProgress:
                return next == RollingPriorityAssignmentStatus.completed || next == RollingPriorityAssignmentStatus.cancelled
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

        func moveTo(_ next: RollingPriorityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return ((dosageMg + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RollingPriorityAssignment {
            return RollingPriorityAssignment(
                code: code,
                label: label,
                dosageMg: dosageMg,
                allergy: allergy,
                bed: bed,
                segment: segment,
                revision: revision,
                floorValue: floorValue,
                threshold: threshold,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling priority assignment in status planned.
    static func newRollingPriorityAssignment(_ code: String, label: String) -> RollingPriorityAssignment {
        return RollingPriorityAssignment(
            code: code,
            label: label,
            dosageMg: 0.0,
            allergy: "",
            bed: "",
            segment: "",
            revision: 0,
            floorValue: 0.0,
            threshold: 0.0,
            title: "",
            status: RollingPriorityAssignmentStatus.planned
        )
    }
}
