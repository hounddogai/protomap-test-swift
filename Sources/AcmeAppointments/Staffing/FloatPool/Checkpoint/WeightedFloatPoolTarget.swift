import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted float pool target is in its life cycle.
    enum WeightedFloatPoolTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted float pool target as the float pool team keeps it.
    final class WeightedFloatPoolTarget {
        var code: String
        var label: String
        var maximum: Double
        var source: String
        var quantity: Int
        var status: WeightedFloatPoolTargetStatus

        init(code: String, label: String, maximum: Double, source: String, quantity: Int, status: WeightedFloatPoolTargetStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.source = source
            self.quantity = quantity
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

        func canMoveTo(_ next: WeightedFloatPoolTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedFloatPoolTargetStatus.ready
            case .warming:
                return next == WeightedFloatPoolTargetStatus.draining || next == WeightedFloatPoolTargetStatus.stopped
            case .ready:
                return next == WeightedFloatPoolTargetStatus.draining || next == WeightedFloatPoolTargetStatus.stopped
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

        func moveTo(_ next: WeightedFloatPoolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted float pool target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted float pool target") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(quantity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> WeightedFloatPoolTarget {
            return WeightedFloatPoolTarget(
                code: code,
                label: label,
                maximum: maximum,
                source: source,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted float pool target in status idle.
    static func newWeightedFloatPoolTarget(_ code: String, label: String) -> WeightedFloatPoolTarget {
        return WeightedFloatPoolTarget(
            code: code,
            label: label,
            maximum: 0.0,
            source: "",
            quantity: 0,
            status: WeightedFloatPoolTargetStatus.idle
        )
    }
}
