import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool bundle is in its life cycle.
    enum ScheduledFloatPoolBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled float pool bundle as the float pool team keeps it.
    final class ScheduledFloatPoolBundle {
        var code: String
        var name: String
        var copay: Double
        var segment: String
        var priority: Int
        var quantity: Int
        var status: ScheduledFloatPoolBundleStatus

        init(code: String, name: String, copay: Double, segment: String, priority: Int, quantity: Int, status: ScheduledFloatPoolBundleStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.segment = segment
            self.priority = priority
            self.quantity = quantity
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

        func canMoveTo(_ next: ScheduledFloatPoolBundleStatus) -> Bool {
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
                return next == ScheduledFloatPoolBundleStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledFloatPoolBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFloatPoolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(priority) + copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFloatPoolBundle {
            return ScheduledFloatPoolBundle(
                code: code,
                name: name,
                copay: copay,
                segment: segment,
                priority: priority,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled float pool bundle in status planned.
    static func newScheduledFloatPoolBundle(_ code: String, name: String) -> ScheduledFloatPoolBundle {
        return ScheduledFloatPoolBundle(
            code: code,
            name: name,
            copay: 0.0,
            segment: "",
            priority: 0,
            quantity: 0,
            status: ScheduledFloatPoolBundleStatus.planned
        )
    }
}
