import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge score is in its life cycle.
    enum ChargeScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One charge score, with what the planners need to act on it.
    final class ChargeScore {
        var code: String
        var title: String
        var ceiling: Double
        var acuity: Int
        var durationMinutes: Int
        var cost: Double
        var revision: Int
        var timezone: String
        var status: ChargeScoreStatus

        init(code: String, title: String, ceiling: Double, acuity: Int, durationMinutes: Int, cost: Double, revision: Int, timezone: String, status: ChargeScoreStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.acuity = acuity
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.revision = revision
            self.timezone = timezone
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

        func canMoveTo(_ next: ChargeScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeScoreStatus.scheduled
            case .scheduled:
                return next == ChargeScoreStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ChargeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return ((ceiling + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeScore {
            return ChargeScore(
                code: code,
                title: title,
                ceiling: ceiling,
                acuity: acuity,
                durationMinutes: durationMinutes,
                cost: cost,
                revision: revision,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge score in status planned.
    static func newChargeScore(_ code: String, title: String) -> ChargeScore {
        return ChargeScore(
            code: code,
            title: title,
            ceiling: 0.0,
            acuity: 0,
            durationMinutes: 0,
            cost: 0.0,
            revision: 0,
            timezone: "",
            status: ChargeScoreStatus.planned
        )
    }
}
