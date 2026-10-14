import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary claim window is in its life cycle.
    enum PrimaryClaimWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary claim window, with what the planners need to act on it.
    final class PrimaryClaimWindow {
        var code: String
        var name: String
        var maximum: Double
        var priority: Int
        var reviewer: String
        var limit: Int
        var endsAt: Int
        var status: PrimaryClaimWindowStatus

        init(code: String, name: String, maximum: Double, priority: Int, reviewer: String, limit: Int, endsAt: Int, status: PrimaryClaimWindowStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.priority = priority
            self.reviewer = reviewer
            self.limit = limit
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryClaimWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryClaimWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryClaimWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary claim window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary claim window") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(limit) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClaimWindow {
            return PrimaryClaimWindow(
                code: code,
                name: name,
                maximum: maximum,
                priority: priority,
                reviewer: reviewer,
                limit: limit,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary claim window in status proposed.
    static func newPrimaryClaimWindow(_ code: String, name: String) -> PrimaryClaimWindow {
        return PrimaryClaimWindow(
            code: code,
            name: name,
            maximum: 0.0,
            priority: 0,
            reviewer: "",
            limit: 0,
            endsAt: 0,
            status: PrimaryClaimWindowStatus.proposed
        )
    }
}
