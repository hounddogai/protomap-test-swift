import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form rollup is in its life cycle.
    enum ConsentFormRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A consent form rollup as the consent form team keeps it.
    final class ConsentFormRollup {
        var code: String
        var label: String
        var maximum: Double
        var graceDays: Int
        var cost: Double
        var status: ConsentFormRollupStatus

        init(code: String, label: String, maximum: Double, graceDays: Int, cost: Double, status: ConsentFormRollupStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.graceDays = graceDays
            self.cost = cost
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

        func canMoveTo(_ next: ConsentFormRollupStatus) -> Bool {
            switch status {
            case .planned:
                return next == ConsentFormRollupStatus.inProgress || next == ConsentFormRollupStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ConsentFormRollupStatus.completed || next == ConsentFormRollupStatus.cancelled
            case .completed:
                return next == ConsentFormRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (maximum * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormRollup {
            return ConsentFormRollup(
                code: code,
                label: label,
                maximum: maximum,
                graceDays: graceDays,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a consent form rollup in status planned.
    static func newConsentFormRollup(_ code: String, label: String) -> ConsentFormRollup {
        return ConsentFormRollup(
            code: code,
            label: label,
            maximum: 0.0,
            graceDays: 0,
            cost: 0.0,
            status: ConsentFormRollupStatus.planned
        )
    }
}
