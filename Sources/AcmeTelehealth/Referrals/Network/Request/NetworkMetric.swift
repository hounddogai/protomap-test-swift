import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network metric is in its life cycle.
    enum NetworkMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network metric as the network team keeps it.
    final class NetworkMetric {
        var code: String
        var label: String
        var windowDays: Int
        var ward: String
        var description: String
        var allergy: String
        var externalRef: String
        var status: NetworkMetricStatus

        init(code: String, label: String, windowDays: Int, ward: String, description: String, allergy: String, externalRef: String, status: NetworkMetricStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.ward = ward
            self.description = description
            self.allergy = allergy
            self.externalRef = externalRef
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

        func canMoveTo(_ next: NetworkMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == NetworkMetricStatus.inProgress || next == NetworkMetricStatus.cancelled
            case .scheduled:
                return next == NetworkMetricStatus.cancelled
            case .inProgress:
                return next == NetworkMetricStatus.completed || next == NetworkMetricStatus.cancelled
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

        func moveTo(_ next: NetworkMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> NetworkMetric {
            return NetworkMetric(
                code: code,
                label: label,
                windowDays: windowDays,
                ward: ward,
                description: description,
                allergy: allergy,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a network metric in status planned.
    static func newNetworkMetric(_ code: String, label: String) -> NetworkMetric {
        return NetworkMetric(
            code: code,
            label: label,
            windowDays: 0,
            ward: "",
            description: "",
            allergy: "",
            externalRef: "",
            status: NetworkMetricStatus.planned
        )
    }
}
