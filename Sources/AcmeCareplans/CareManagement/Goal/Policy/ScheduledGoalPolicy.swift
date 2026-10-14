import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled goal policy is in its life cycle.
    enum ScheduledGoalPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled goal policy as the goal team keeps it.
    final class ScheduledGoalPolicy {
        var code: String
        var title: String
        var durationMinutes: Int
        var endsAt: Int
        var limit: Int
        var locale: String
        var updatedAt: Int
        var ratio: Double
        var refills: Int
        var priority: Int
        var phone: String
        var status: ScheduledGoalPolicyStatus

        init(code: String, title: String, durationMinutes: Int, endsAt: Int, limit: Int, locale: String, updatedAt: Int, ratio: Double, refills: Int, priority: Int, phone: String, status: ScheduledGoalPolicyStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.endsAt = endsAt
            self.limit = limit
            self.locale = locale
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.refills = refills
            self.priority = priority
            self.phone = phone
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

        func canMoveTo(_ next: ScheduledGoalPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledGoalPolicyStatus.pending || next == ScheduledGoalPolicyStatus.suspended
            case .pending:
                return next == ScheduledGoalPolicyStatus.active || next == ScheduledGoalPolicyStatus.closed
            case .active:
                return next == ScheduledGoalPolicyStatus.suspended || next == ScheduledGoalPolicyStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ScheduledGoalPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled goal policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netValue() -> Double {
            return (Double(durationMinutes) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledGoalPolicy {
            return ScheduledGoalPolicy(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                endsAt: endsAt,
                limit: limit,
                locale: locale,
                updatedAt: updatedAt,
                ratio: ratio,
                refills: refills,
                priority: priority,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled goal policy in status draft.
    static func newScheduledGoalPolicy(_ code: String, title: String) -> ScheduledGoalPolicy {
        return ScheduledGoalPolicy(
            code: code,
            title: title,
            durationMinutes: 0,
            endsAt: 0,
            limit: 0,
            locale: "",
            updatedAt: 0,
            ratio: 0.0,
            refills: 0,
            priority: 0,
            phone: "",
            status: ScheduledGoalPolicyStatus.draft
        )
    }
}
