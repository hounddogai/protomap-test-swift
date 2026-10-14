import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual skill mix schedule is in its life cycle.
    enum ManualSkillMixScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One manual skill mix schedule, with what the planners need to act on it.
    final class ManualSkillMixSchedule {
        var code: String
        var label: String
        var name: String
        var rate: Double
        var minimum: Double
        var version: Int
        var budget: Double
        var windowDays: Int
        var pinned: Bool
        var status: ManualSkillMixScheduleStatus

        init(code: String, label: String, name: String, rate: Double, minimum: Double, version: Int, budget: Double, windowDays: Int, pinned: Bool, status: ManualSkillMixScheduleStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.rate = rate
            self.minimum = minimum
            self.version = version
            self.budget = budget
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ManualSkillMixScheduleStatus) -> Bool {
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
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ManualSkillMixScheduleStatus.completed || next == ManualSkillMixScheduleStatus.cancelled
            case .completed:
                return next == ManualSkillMixScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSkillMixScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual skill mix schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("manual skill mix schedule") \(code)"
        }

        func weightedExposure() -> Double {
            return (budget * minimum * 100).rounded() / 100
        }

        func copyValue() -> ManualSkillMixSchedule {
            return ManualSkillMixSchedule(
                code: code,
                label: label,
                name: name,
                rate: rate,
                minimum: minimum,
                version: version,
                budget: budget,
                windowDays: windowDays,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual skill mix schedule in status planned.
    static func newManualSkillMixSchedule(_ code: String, label: String) -> ManualSkillMixSchedule {
        return ManualSkillMixSchedule(
            code: code,
            label: label,
            name: "",
            rate: 0.0,
            minimum: 0.0,
            version: 0,
            budget: 0.0,
            windowDays: 0,
            pinned: false,
            status: ManualSkillMixScheduleStatus.planned
        )
    }
}
