import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form assignment is in its life cycle.
    enum PrimaryConsentFormAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary consent form assignment as the consent form team keeps it.
    final class PrimaryConsentFormAssignment {
        var code: String
        var name: String
        var cost: Double
        var timezone: String
        var minimum: Double
        var country: String
        var budget: Double
        var priority: Int
        var visitMinutes: Int
        var status: PrimaryConsentFormAssignmentStatus

        init(code: String, name: String, cost: Double, timezone: String, minimum: Double, country: String, budget: Double, priority: Int, visitMinutes: Int, status: PrimaryConsentFormAssignmentStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.timezone = timezone
            self.minimum = minimum
            self.country = country
            self.budget = budget
            self.priority = priority
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PrimaryConsentFormAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryConsentFormAssignmentStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PrimaryConsentFormAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryConsentFormAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((minimum + budget) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormAssignment {
            return PrimaryConsentFormAssignment(
                code: code,
                name: name,
                cost: cost,
                timezone: timezone,
                minimum: minimum,
                country: country,
                budget: budget,
                priority: priority,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary consent form assignment in status planned.
    static func newPrimaryConsentFormAssignment(_ code: String, name: String) -> PrimaryConsentFormAssignment {
        return PrimaryConsentFormAssignment(
            code: code,
            name: name,
            cost: 0.0,
            timezone: "",
            minimum: 0.0,
            country: "",
            budget: 0.0,
            priority: 0,
            visitMinutes: 0,
            status: PrimaryConsentFormAssignmentStatus.planned
        )
    }
}
