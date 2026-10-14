import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled goal preference is in its life cycle.
    enum ScheduledGoalPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled goal preference, with what the planners need to act on it.
    final class ScheduledGoalPreference {
        var code: String
        var name: String
        var budget: Double
        var segment: String
        var timezone: String
        var country: String
        var procedureCode: String
        var weight: Double
        var status: ScheduledGoalPreferenceStatus

        init(code: String, name: String, budget: Double, segment: String, timezone: String, country: String, procedureCode: String, weight: Double, status: ScheduledGoalPreferenceStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.segment = segment
            self.timezone = timezone
            self.country = country
            self.procedureCode = procedureCode
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledGoalPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledGoalPreferenceStatus.active || next == ScheduledGoalPreferenceStatus.suspended
            case .active:
                return next == ScheduledGoalPreferenceStatus.closed
            case .suspended:
                return next == ScheduledGoalPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledGoalPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled goal preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((weight - budget) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledGoalPreference {
            return ScheduledGoalPreference(
                code: code,
                name: name,
                budget: budget,
                segment: segment,
                timezone: timezone,
                country: country,
                procedureCode: procedureCode,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled goal preference in status draft.
    static func newScheduledGoalPreference(_ code: String, name: String) -> ScheduledGoalPreference {
        return ScheduledGoalPreference(
            code: code,
            name: name,
            budget: 0.0,
            segment: "",
            timezone: "",
            country: "",
            procedureCode: "",
            weight: 0.0,
            status: ScheduledGoalPreferenceStatus.draft
        )
    }
}
