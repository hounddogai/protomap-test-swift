import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy isolation allocation is in its life cycle.
    enum LegacyIsolationAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy isolation allocation and its current status.
    final class LegacyIsolationAllocation {
        var code: String
        var title: String
        var ratio: Double
        var priority: Int
        var weight: Double
        var pinned: Bool
        var description: String
        var currency: String
        var status: LegacyIsolationAllocationStatus

        init(code: String, title: String, ratio: Double, priority: Int, weight: Double, pinned: Bool, description: String, currency: String, status: LegacyIsolationAllocationStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.priority = priority
            self.weight = weight
            self.pinned = pinned
            self.description = description
            self.currency = currency
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

        func canMoveTo(_ next: LegacyIsolationAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: LegacyIsolationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy isolation allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return ((ratio + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyIsolationAllocation {
            return LegacyIsolationAllocation(
                code: code,
                title: title,
                ratio: ratio,
                priority: priority,
                weight: weight,
                pinned: pinned,
                description: description,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy isolation allocation in status planned.
    static func newLegacyIsolationAllocation(_ code: String, title: String) -> LegacyIsolationAllocation {
        return LegacyIsolationAllocation(
            code: code,
            title: title,
            ratio: 0.0,
            priority: 0,
            weight: 0.0,
            pinned: false,
            description: "",
            currency: "",
            status: LegacyIsolationAllocationStatus.planned
        )
    }
}
