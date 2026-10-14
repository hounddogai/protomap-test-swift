import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation metric is in its life cycle.
    enum IsolationMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A isolation metric as the isolation team keeps it.
    final class IsolationMetric {
        var code: String
        var name: String
        var maximum: Double
        var graceDays: Int
        var ratio: Double
        var weight: Double
        var quantity: Int
        var ceiling: Double
        var copay: Double
        var status: IsolationMetricStatus

        init(code: String, name: String, maximum: Double, graceDays: Int, ratio: Double, weight: Double, quantity: Int, ceiling: Double, copay: Double, status: IsolationMetricStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.graceDays = graceDays
            self.ratio = ratio
            self.weight = weight
            self.quantity = quantity
            self.ceiling = ceiling
            self.copay = copay
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

        func canMoveTo(_ next: IsolationMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: IsolationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(quantity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> IsolationMetric {
            return IsolationMetric(
                code: code,
                name: name,
                maximum: maximum,
                graceDays: graceDays,
                ratio: ratio,
                weight: weight,
                quantity: quantity,
                ceiling: ceiling,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation metric in status idle.
    static func newIsolationMetric(_ code: String, name: String) -> IsolationMetric {
        return IsolationMetric(
            code: code,
            name: name,
            maximum: 0.0,
            graceDays: 0,
            ratio: 0.0,
            weight: 0.0,
            quantity: 0,
            ceiling: 0.0,
            copay: 0.0,
            status: IsolationMetricStatus.idle
        )
    }
}
