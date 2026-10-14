import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool metric is in its life cycle.
    enum FloatPoolMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One float pool metric, with what the planners need to act on it.
    final class FloatPoolMetric {
        var code: String
        var title: String
        var score: Double
        var sequence: Int
        var description: String
        var active: Bool
        var name: String
        var windowDays: Int
        var status: FloatPoolMetricStatus

        init(code: String, title: String, score: Double, sequence: Int, description: String, active: Bool, name: String, windowDays: Int, status: FloatPoolMetricStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.sequence = sequence
            self.description = description
            self.active = active
            self.name = name
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FloatPoolMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FloatPoolMetricStatus.rejected || next == FloatPoolMetricStatus.withdrawn
            case .approved:
                return next == FloatPoolMetricStatus.rejected || next == FloatPoolMetricStatus.withdrawn
            case .rejected:
                return next == FloatPoolMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((Double(windowDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolMetric {
            return FloatPoolMetric(
                code: code,
                title: title,
                score: score,
                sequence: sequence,
                description: description,
                active: active,
                name: name,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool metric in status proposed.
    static func newFloatPoolMetric(_ code: String, title: String) -> FloatPoolMetric {
        return FloatPoolMetric(
            code: code,
            title: title,
            score: 0.0,
            sequence: 0,
            description: "",
            active: false,
            name: "",
            windowDays: 0,
            status: FloatPoolMetricStatus.proposed
        )
    }
}
