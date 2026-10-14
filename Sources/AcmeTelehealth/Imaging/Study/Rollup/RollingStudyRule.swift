import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study rule is in its life cycle.
    enum RollingStudyRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rolling study rule and its current status.
    final class RollingStudyRule {
        var code: String
        var name: String
        var retries: Int
        var startsAt: Int
        var active: Bool
        var budget: Double
        var status: RollingStudyRuleStatus

        init(code: String, name: String, retries: Int, startsAt: Int, active: Bool, budget: Double, status: RollingStudyRuleStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.startsAt = startsAt
            self.active = active
            self.budget = budget
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

        func canMoveTo(_ next: RollingStudyRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingStudyRuleStatus.ready || next == RollingStudyRuleStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RollingStudyRuleStatus.draining || next == RollingStudyRuleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RollingStudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling study rule") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(retries) + budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingStudyRule {
            return RollingStudyRule(
                code: code,
                name: name,
                retries: retries,
                startsAt: startsAt,
                active: active,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling study rule in status idle.
    static func newRollingStudyRule(_ code: String, name: String) -> RollingStudyRule {
        return RollingStudyRule(
            code: code,
            name: name,
            retries: 0,
            startsAt: 0,
            active: false,
            budget: 0.0,
            status: RollingStudyRuleStatus.idle
        )
    }
}
