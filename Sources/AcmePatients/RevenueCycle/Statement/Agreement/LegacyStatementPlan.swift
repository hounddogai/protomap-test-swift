import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy statement plan is in its life cycle.
    enum LegacyStatementPlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a legacy statement plan and its current status.
    final class LegacyStatementPlan {
        var code: String
        var label: String
        var updatedAt: Int
        var attempts: Int
        var active: Bool
        var status: LegacyStatementPlanStatus

        init(code: String, label: String, updatedAt: Int, attempts: Int, active: Bool, status: LegacyStatementPlanStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyStatementPlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LegacyStatementPlanStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyStatementPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy statement plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("legacy statement plan") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStatementPlan {
            return LegacyStatementPlan(
                code: code,
                label: label,
                updatedAt: updatedAt,
                attempts: attempts,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy statement plan in status idle.
    static func newLegacyStatementPlan(_ code: String, label: String) -> LegacyStatementPlan {
        return LegacyStatementPlan(
            code: code,
            label: label,
            updatedAt: 0,
            attempts: 0,
            active: false,
            status: LegacyStatementPlanStatus.idle
        )
    }
}
