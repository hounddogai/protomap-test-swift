import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding baseline is in its life cycle.
    enum RoundingBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rounding baseline, with what the planners need to act on it.
    final class RoundingBaseline {
        var code: String
        var name: String
        var attempts: Int
        var approved: Bool
        var label: String
        var status: RoundingBaselineStatus

        init(code: String, name: String, attempts: Int, approved: Bool, label: String, status: RoundingBaselineStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.approved = approved
            self.label = label
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

        func canMoveTo(_ next: RoundingBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == RoundingBaselineStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RoundingBaselineStatus.completed || next == RoundingBaselineStatus.cancelled
            case .completed:
                return next == RoundingBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> RoundingBaseline {
            return RoundingBaseline(
                code: code,
                name: name,
                attempts: attempts,
                approved: approved,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding baseline in status planned.
    static func newRoundingBaseline(_ code: String, name: String) -> RoundingBaseline {
        return RoundingBaseline(
            code: code,
            name: name,
            attempts: 0,
            approved: false,
            label: "",
            status: RoundingBaselineStatus.planned
        )
    }
}
