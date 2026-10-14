import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up metric is in its life cycle.
    enum FollowUpMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A follow up metric. Its code is unique within a tenant.
    final class FollowUpMetric {
        var code: String
        var label: String
        var ratio: Double
        var bed: String
        var channel: String
        var status: FollowUpMetricStatus

        init(code: String, label: String, ratio: Double, bed: String, channel: String, status: FollowUpMetricStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.bed = bed
            self.channel = channel
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

        func canMoveTo(_ next: FollowUpMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FollowUpMetricStatus.withdrawn
            case .rejected:
                return next == FollowUpMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up metric") \(code)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> FollowUpMetric {
            return FollowUpMetric(code: code, label: label, ratio: ratio, bed: bed, channel: channel, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a follow up metric in status proposed.
    static func newFollowUpMetric(_ code: String, label: String) -> FollowUpMetric {
        return FollowUpMetric(
            code: code,
            label: label,
            ratio: 0.0,
            bed: "",
            channel: "",
            status: FollowUpMetricStatus.proposed
        )
    }
}
