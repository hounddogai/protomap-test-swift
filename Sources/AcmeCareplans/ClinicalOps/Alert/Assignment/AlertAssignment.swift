import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert assignment is in its life cycle.
    enum AlertAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A alert assignment as the alert team keeps it.
    final class AlertAssignment {
        var code: String
        var title: String
        var clinicianID: String
        var ceiling: Double
        var revision: Int
        var specialty: String
        var capacity: Int
        var status: AlertAssignmentStatus

        init(code: String, title: String, clinicianID: String, ceiling: Double, revision: Int, specialty: String, capacity: Int, status: AlertAssignmentStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.revision = revision
            self.specialty = specialty
            self.capacity = capacity
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

        func canMoveTo(_ next: AlertAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AlertAssignmentStatus.resolved
            case .inReview:
                return next == AlertAssignmentStatus.resolved || next == AlertAssignmentStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AlertAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(capacity) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AlertAssignment {
            return AlertAssignment(
                code: code,
                title: title,
                clinicianID: clinicianID,
                ceiling: ceiling,
                revision: revision,
                specialty: specialty,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert assignment in status open.
    static func newAlertAssignment(_ code: String, title: String) -> AlertAssignment {
        return AlertAssignment(
            code: code,
            title: title,
            clinicianID: "",
            ceiling: 0.0,
            revision: 0,
            specialty: "",
            capacity: 0,
            status: AlertAssignmentStatus.`open`
        )
    }
}
