import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift allocation is in its life cycle.
    enum DefaultShiftAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default shift allocation. Its code is unique within a tenant.
    final class DefaultShiftAllocation {
        var code: String
        var name: String
        var priority: Int
        var retries: Int
        var rate: Double
        var reviewer: String
        var status: DefaultShiftAllocationStatus

        init(code: String, name: String, priority: Int, retries: Int, rate: Double, reviewer: String, status: DefaultShiftAllocationStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.retries = retries
            self.rate = rate
            self.reviewer = reviewer
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

        func canMoveTo(_ next: DefaultShiftAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
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
                return next == DefaultShiftAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultShiftAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default shift allocation") \(code)"
        }

        func adjustedVolume() -> Double {
            return (rate * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> DefaultShiftAllocation {
            return DefaultShiftAllocation(
                code: code,
                name: name,
                priority: priority,
                retries: retries,
                rate: rate,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default shift allocation in status planned.
    static func newDefaultShiftAllocation(_ code: String, name: String) -> DefaultShiftAllocation {
        return DefaultShiftAllocation(
            code: code,
            name: name,
            priority: 0,
            retries: 0,
            rate: 0.0,
            reviewer: "",
            status: DefaultShiftAllocationStatus.planned
        )
    }
}
