import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling courier threshold is in its life cycle.
    enum RollingCourierThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling courier threshold, with what the planners need to act on it.
    final class RollingCourierThreshold {
        var code: String
        var title: String
        var payer: String
        var region: String
        var maximum: Double
        var rate: Double
        var status: RollingCourierThresholdStatus

        init(code: String, title: String, payer: String, region: String, maximum: Double, rate: Double, status: RollingCourierThresholdStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.region = region
            self.maximum = maximum
            self.rate = rate
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

        func canMoveTo(_ next: RollingCourierThresholdStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingCourierThresholdStatus.inProgress || next == RollingCourierThresholdStatus.completed
            case .scheduled:
                return next == RollingCourierThresholdStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingCourierThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCourierThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling courier threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling courier threshold") \(code)"
        }

        func weightedLoad() -> Double {
            return ((maximum - rate) * 100).rounded() / 100
        }

        func copyValue() -> RollingCourierThreshold {
            return RollingCourierThreshold(
                code: code,
                title: title,
                payer: payer,
                region: region,
                maximum: maximum,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling courier threshold in status planned.
    static func newRollingCourierThreshold(_ code: String, title: String) -> RollingCourierThreshold {
        return RollingCourierThreshold(
            code: code,
            title: title,
            payer: "",
            region: "",
            maximum: 0.0,
            rate: 0.0,
            status: RollingCourierThresholdStatus.planned
        )
    }
}
