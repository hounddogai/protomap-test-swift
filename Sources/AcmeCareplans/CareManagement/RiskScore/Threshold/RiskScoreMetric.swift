import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score metric is in its life cycle.
    enum RiskScoreMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A risk score metric as the risk score team keeps it.
    final class RiskScoreMetric {
        var code: String
        var name: String
        var title: String
        var segment: String
        var maximum: Double
        var source: String
        var status: RiskScoreMetricStatus

        init(code: String, name: String, title: String, segment: String, maximum: Double, source: String, status: RiskScoreMetricStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.segment = segment
            self.maximum = maximum
            self.source = source
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

        func canMoveTo(_ next: RiskScoreMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RiskScoreMetricStatus.completed || next == RiskScoreMetricStatus.cancelled
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

        func moveTo(_ next: RiskScoreMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> RiskScoreMetric {
            return RiskScoreMetric(
                code: code,
                name: name,
                title: title,
                segment: segment,
                maximum: maximum,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a risk score metric in status planned.
    static func newRiskScoreMetric(_ code: String, name: String) -> RiskScoreMetric {
        return RiskScoreMetric(
            code: code,
            name: name,
            title: "",
            segment: "",
            maximum: 0.0,
            source: "",
            status: RiskScoreMetricStatus.planned
        )
    }
}
