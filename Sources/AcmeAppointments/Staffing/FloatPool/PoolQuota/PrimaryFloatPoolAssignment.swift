import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary float pool assignment is in its life cycle.
    enum PrimaryFloatPoolAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary float pool assignment. Its code is unique within a tenant.
    final class PrimaryFloatPoolAssignment {
        var code: String
        var label: String
        var archived: Bool
        var checksum: String
        var bed: String
        var graceDays: Int
        var status: PrimaryFloatPoolAssignmentStatus

        init(code: String, label: String, archived: Bool, checksum: String, bed: String, graceDays: Int, status: PrimaryFloatPoolAssignmentStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.checksum = checksum
            self.bed = bed
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PrimaryFloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryFloatPoolAssignmentStatus.inReview || next == PrimaryFloatPoolAssignmentStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryFloatPoolAssignmentStatus.reopened || next == PrimaryFloatPoolAssignmentStatus.archived
            case .reopened:
                return next == PrimaryFloatPoolAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryFloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> PrimaryFloatPoolAssignment {
            return PrimaryFloatPoolAssignment(
                code: code,
                label: label,
                archived: archived,
                checksum: checksum,
                bed: bed,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary float pool assignment in status open.
    static func newPrimaryFloatPoolAssignment(_ code: String, label: String) -> PrimaryFloatPoolAssignment {
        return PrimaryFloatPoolAssignment(
            code: code,
            label: label,
            archived: false,
            checksum: "",
            bed: "",
            graceDays: 0,
            status: PrimaryFloatPoolAssignmentStatus.`open`
        )
    }
}
