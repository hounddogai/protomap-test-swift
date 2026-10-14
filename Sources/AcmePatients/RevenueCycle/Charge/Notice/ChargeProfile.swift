import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge profile is in its life cycle.
    enum ChargeProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a charge profile and its current status.
    final class ChargeProfile {
        var code: String
        var label: String
        var capacity: Int
        var maximum: Double
        var priority: Int
        var status: ChargeProfileStatus

        init(code: String, label: String, capacity: Int, maximum: Double, priority: Int, status: ChargeProfileStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.maximum = maximum
            self.priority = priority
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

        func canMoveTo(_ next: ChargeProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeProfileStatus.inProgress || next == ChargeProfileStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
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

        func moveTo(_ next: ChargeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("charge profile") \(code)"
        }

        func weightedTotal() -> Double {
            return ((maximum + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeProfile {
            return ChargeProfile(
                code: code,
                label: label,
                capacity: capacity,
                maximum: maximum,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a charge profile in status planned.
    static func newChargeProfile(_ code: String, label: String) -> ChargeProfile {
        return ChargeProfile(
            code: code,
            label: label,
            capacity: 0,
            maximum: 0.0,
            priority: 0,
            status: ChargeProfileStatus.planned
        )
    }
}
