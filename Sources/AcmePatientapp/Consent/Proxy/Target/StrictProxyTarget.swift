import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy target is in its life cycle.
    enum StrictProxyTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict proxy target and its current status.
    final class StrictProxyTarget {
        var code: String
        var label: String
        var budget: Double
        var limit: Int
        var floorValue: Double
        var status: StrictProxyTargetStatus

        init(code: String, label: String, budget: Double, limit: Int, floorValue: Double, status: StrictProxyTargetStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.limit = limit
            self.floorValue = floorValue
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

        func canMoveTo(_ next: StrictProxyTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictProxyTargetStatus.ready
            case .warming:
                return next == StrictProxyTargetStatus.ready
            case .ready:
                return next == StrictProxyTargetStatus.draining
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

        func moveTo(_ next: StrictProxyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict proxy target") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((floorValue + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyTarget {
            return StrictProxyTarget(
                code: code,
                label: label,
                budget: budget,
                limit: limit,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict proxy target in status idle.
    static func newStrictProxyTarget(_ code: String, label: String) -> StrictProxyTarget {
        return StrictProxyTarget(
            code: code,
            label: label,
            budget: 0.0,
            limit: 0,
            floorValue: 0.0,
            status: StrictProxyTargetStatus.idle
        )
    }
}
