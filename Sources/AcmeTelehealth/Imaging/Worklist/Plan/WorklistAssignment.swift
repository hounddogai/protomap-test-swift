import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist assignment is in its life cycle.
    enum WorklistAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a worklist assignment and its current status.
    final class WorklistAssignment {
        var code: String
        var title: String
        var approved: Bool
        var checksum: String
        var revision: Int
        var quantity: Int
        var status: WorklistAssignmentStatus

        init(code: String, title: String, approved: Bool, checksum: String, revision: Int, quantity: Int, status: WorklistAssignmentStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.checksum = checksum
            self.revision = revision
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == WorklistAssignmentStatus.expired
            case .granted:
                return next == WorklistAssignmentStatus.revoked || next == WorklistAssignmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WorklistAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("worklist assignment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(revision) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistAssignment {
            return WorklistAssignment(
                code: code,
                title: title,
                approved: approved,
                checksum: checksum,
                revision: revision,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist assignment in status requested.
    static func newWorklistAssignment(_ code: String, title: String) -> WorklistAssignment {
        return WorklistAssignment(
            code: code,
            title: title,
            approved: false,
            checksum: "",
            revision: 0,
            quantity: 0,
            status: WorklistAssignmentStatus.requested
        )
    }
}
