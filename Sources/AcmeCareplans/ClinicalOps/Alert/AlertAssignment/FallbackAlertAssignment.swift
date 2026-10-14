import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback alert assignment is in its life cycle.
    enum FallbackAlertAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback alert assignment. Its code is unique within a tenant.
    final class FallbackAlertAssignment {
        var code: String
        var title: String
        var archived: Bool
        var name: String
        var updatedAt: Int
        var facility: String
        var pinned: Bool
        var status: FallbackAlertAssignmentStatus

        init(code: String, title: String, archived: Bool, name: String, updatedAt: Int, facility: String, pinned: Bool, status: FallbackAlertAssignmentStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.name = name
            self.updatedAt = updatedAt
            self.facility = facility
            self.pinned = pinned
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

        func canMoveTo(_ next: FallbackAlertAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackAlertAssignmentStatus.scheduled || next == FallbackAlertAssignmentStatus.inProgress
            case .scheduled:
                return next == FallbackAlertAssignmentStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackAlertAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAlertAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback alert assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback alert assignment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> FallbackAlertAssignment {
            return FallbackAlertAssignment(
                code: code,
                title: title,
                archived: archived,
                name: name,
                updatedAt: updatedAt,
                facility: facility,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback alert assignment in status planned.
    static func newFallbackAlertAssignment(_ code: String, title: String) -> FallbackAlertAssignment {
        return FallbackAlertAssignment(
            code: code,
            title: title,
            archived: false,
            name: "",
            updatedAt: 0,
            facility: "",
            pinned: false,
            status: FallbackAlertAssignmentStatus.planned
        )
    }
}
