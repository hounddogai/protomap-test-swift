import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff assignment is in its life cycle.
    enum HandoffAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One handoff assignment, with what the planners need to act on it.
    final class HandoffAssignment {
        var code: String
        var label: String
        var ward: String
        var archived: Bool
        var externalRef: String
        var createdAt: Int
        var margin: Double
        var status: HandoffAssignmentStatus

        init(code: String, label: String, ward: String, archived: Bool, externalRef: String, createdAt: Int, margin: Double, status: HandoffAssignmentStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.archived = archived
            self.externalRef = externalRef
            self.createdAt = createdAt
            self.margin = margin
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

        func canMoveTo(_ next: HandoffAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == HandoffAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((margin + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffAssignment {
            return HandoffAssignment(
                code: code,
                label: label,
                ward: ward,
                archived: archived,
                externalRef: externalRef,
                createdAt: createdAt,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a handoff assignment in status planned.
    static func newHandoffAssignment(_ code: String, label: String) -> HandoffAssignment {
        return HandoffAssignment(
            code: code,
            label: label,
            ward: "",
            archived: false,
            externalRef: "",
            createdAt: 0,
            margin: 0.0,
            status: HandoffAssignmentStatus.planned
        )
    }
}
