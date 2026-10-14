import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution assignment is in its life cycle.
    enum SubstitutionAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A substitution assignment as the substitution team keeps it.
    final class SubstitutionAssignment {
        var code: String
        var title: String
        var unit: String
        var rate: Double
        var description: String
        var durationMinutes: Int
        var timezone: String
        var status: SubstitutionAssignmentStatus

        init(code: String, title: String, unit: String, rate: Double, description: String, durationMinutes: Int, timezone: String, status: SubstitutionAssignmentStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.rate = rate
            self.description = description
            self.durationMinutes = durationMinutes
            self.timezone = timezone
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

        func canMoveTo(_ next: SubstitutionAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionAssignmentStatus.resolved || next == SubstitutionAssignmentStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SubstitutionAssignmentStatus.reopened || next == SubstitutionAssignmentStatus.archived
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

        func moveTo(_ next: SubstitutionAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return (rate * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionAssignment {
            return SubstitutionAssignment(
                code: code,
                title: title,
                unit: unit,
                rate: rate,
                description: description,
                durationMinutes: durationMinutes,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a substitution assignment in status open.
    static func newSubstitutionAssignment(_ code: String, title: String) -> SubstitutionAssignment {
        return SubstitutionAssignment(
            code: code,
            title: title,
            unit: "",
            rate: 0.0,
            description: "",
            durationMinutes: 0,
            timezone: "",
            status: SubstitutionAssignmentStatus.`open`
        )
    }
}
