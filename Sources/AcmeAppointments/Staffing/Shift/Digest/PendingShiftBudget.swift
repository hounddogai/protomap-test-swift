import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending shift budget is in its life cycle.
    enum PendingShiftBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending shift budget, with what the planners need to act on it.
    final class PendingShiftBudget {
        var code: String
        var title: String
        var startsAt: Int
        var locale: String
        var clinicianID: String
        var endsAt: Int
        var encounterID: String
        var windowDays: Int
        var status: PendingShiftBudgetStatus

        init(code: String, title: String, startsAt: Int, locale: String, clinicianID: String, endsAt: Int, encounterID: String, windowDays: Int, status: PendingShiftBudgetStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.locale = locale
            self.clinicianID = clinicianID
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.windowDays = windowDays
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

        func canMoveTo(_ next: PendingShiftBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingShiftBudgetStatus.inProgress || next == PendingShiftBudgetStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingShiftBudgetStatus.completed || next == PendingShiftBudgetStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingShiftBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending shift budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((Double(windowDays) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingShiftBudget {
            return PendingShiftBudget(
                code: code,
                title: title,
                startsAt: startsAt,
                locale: locale,
                clinicianID: clinicianID,
                endsAt: endsAt,
                encounterID: encounterID,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending shift budget in status planned.
    static func newPendingShiftBudget(_ code: String, title: String) -> PendingShiftBudget {
        return PendingShiftBudget(
            code: code,
            title: title,
            startsAt: 0,
            locale: "",
            clinicianID: "",
            endsAt: 0,
            encounterID: "",
            windowDays: 0,
            status: PendingShiftBudgetStatus.planned
        )
    }
}
