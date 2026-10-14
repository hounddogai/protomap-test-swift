import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier metric is in its life cycle.
    enum DefaultCourierMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One default courier metric, with what the planners need to act on it.
    final class DefaultCourierMetric {
        var code: String
        var label: String
        var priority: Int
        var batchSize: Int
        var floorValue: Double
        var status: DefaultCourierMetricStatus

        init(code: String, label: String, priority: Int, batchSize: Int, floorValue: Double, status: DefaultCourierMetricStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.batchSize = batchSize
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCourierMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultCourierMetricStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DefaultCourierMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (Double(batchSize) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierMetric {
            return DefaultCourierMetric(
                code: code,
                label: label,
                priority: priority,
                batchSize: batchSize,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default courier metric in status proposed.
    static func newDefaultCourierMetric(_ code: String, label: String) -> DefaultCourierMetric {
        return DefaultCourierMetric(
            code: code,
            label: label,
            priority: 0,
            batchSize: 0,
            floorValue: 0.0,
            status: DefaultCourierMetricStatus.proposed
        )
    }
}
