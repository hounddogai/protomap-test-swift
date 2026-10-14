import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled closure draft is in its life cycle.
    enum ScheduledClosureDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled closure draft, with what the planners need to act on it.
    final class ScheduledClosureDraft {
        var code: String
        var name: String
        var amount: Double
        var ceiling: Double
        var priority: Int
        var status: ScheduledClosureDraftStatus

        init(code: String, name: String, amount: Double, ceiling: Double, priority: Int, status: ScheduledClosureDraftStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.ceiling = ceiling
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledClosureDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ScheduledClosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled closure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled closure draft") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledClosureDraft {
            return ScheduledClosureDraft(
                code: code,
                name: name,
                amount: amount,
                ceiling: ceiling,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled closure draft in status requested.
    static func newScheduledClosureDraft(_ code: String, name: String) -> ScheduledClosureDraft {
        return ScheduledClosureDraft(
            code: code,
            name: name,
            amount: 0.0,
            ceiling: 0.0,
            priority: 0,
            status: ScheduledClosureDraftStatus.requested
        )
    }
}
