import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled worklist assignment is in its life cycle.
    enum ScheduledWorklistAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled worklist assignment and its current status.
    final class ScheduledWorklistAssignment {
        var code: String
        var name: String
        var description: String
        var active: Bool
        var graceDays: Int
        var allergy: String
        var retries: Int
        var dosageMg: Double
        var procedureCode: String
        var expiresAt: Int
        var status: ScheduledWorklistAssignmentStatus

        init(code: String, name: String, description: String, active: Bool, graceDays: Int, allergy: String, retries: Int, dosageMg: Double, procedureCode: String, expiresAt: Int, status: ScheduledWorklistAssignmentStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.active = active
            self.graceDays = graceDays
            self.allergy = allergy
            self.retries = retries
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ScheduledWorklistAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledWorklistAssignmentStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ScheduledWorklistAssignmentStatus.reopened || next == ScheduledWorklistAssignmentStatus.archived
            case .reopened:
                return next == ScheduledWorklistAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledWorklistAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled worklist assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((Double(graceDays) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledWorklistAssignment {
            return ScheduledWorklistAssignment(
                code: code,
                name: name,
                description: description,
                active: active,
                graceDays: graceDays,
                allergy: allergy,
                retries: retries,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled worklist assignment in status open.
    static func newScheduledWorklistAssignment(_ code: String, name: String) -> ScheduledWorklistAssignment {
        return ScheduledWorklistAssignment(
            code: code,
            name: name,
            description: "",
            active: false,
            graceDays: 0,
            allergy: "",
            retries: 0,
            dosageMg: 0.0,
            procedureCode: "",
            expiresAt: 0,
            status: ScheduledWorklistAssignmentStatus.`open`
        )
    }
}
