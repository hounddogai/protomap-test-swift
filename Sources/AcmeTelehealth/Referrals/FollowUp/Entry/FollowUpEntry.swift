import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up entry is in its life cycle.
    enum FollowUpEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A follow up entry. Its code is unique within a tenant.
    final class FollowUpEntry {
        var code: String
        var name: String
        var visitMinutes: Int
        var score: Double
        var active: Bool
        var startsAt: Int
        var windowDays: Int
        var capacity: Int
        var timezone: String
        var status: FollowUpEntryStatus

        init(code: String, name: String, visitMinutes: Int, score: Double, active: Bool, startsAt: Int, windowDays: Int, capacity: Int, timezone: String, status: FollowUpEntryStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.score = score
            self.active = active
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.capacity = capacity
            self.timezone = timezone
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

        func canMoveTo(_ next: FollowUpEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FollowUpEntryStatus.active || next == FollowUpEntryStatus.suspended
            case .active:
                return next == FollowUpEntryStatus.closed
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

        func moveTo(_ next: FollowUpEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return (score * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpEntry {
            return FollowUpEntry(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                score: score,
                active: active,
                startsAt: startsAt,
                windowDays: windowDays,
                capacity: capacity,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up entry in status draft.
    static func newFollowUpEntry(_ code: String, name: String) -> FollowUpEntry {
        return FollowUpEntry(
            code: code,
            name: name,
            visitMinutes: 0,
            score: 0.0,
            active: false,
            startsAt: 0,
            windowDays: 0,
            capacity: 0,
            timezone: "",
            status: FollowUpEntryStatus.draft
        )
    }
}
