import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient study target is in its life cycle.
    enum LenientStudyTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient study target. Its code is unique within a tenant.
    final class LenientStudyTarget {
        var code: String
        var name: String
        var cost: Double
        var rate: Double
        var graceDays: Int
        var status: LenientStudyTargetStatus

        init(code: String, name: String, cost: Double, rate: Double, graceDays: Int, status: LenientStudyTargetStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.rate = rate
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LenientStudyTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientStudyTargetStatus.inProgress
            case .inProgress:
                return next == LenientStudyTargetStatus.completed || next == LenientStudyTargetStatus.cancelled
            case .completed:
                return next == LenientStudyTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientStudyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient study target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return ((cost + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientStudyTarget {
            return LenientStudyTarget(
                code: code,
                name: name,
                cost: cost,
                rate: rate,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient study target in status planned.
    static func newLenientStudyTarget(_ code: String, name: String) -> LenientStudyTarget {
        return LenientStudyTarget(
            code: code,
            name: name,
            cost: 0.0,
            rate: 0.0,
            graceDays: 0,
            status: LenientStudyTargetStatus.planned
        )
    }
}
