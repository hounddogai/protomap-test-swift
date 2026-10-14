import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result metric is in its life cycle.
    enum PendingResultMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending result metric as the result team keeps it.
    final class PendingResultMetric {
        var code: String
        var label: String
        var externalRef: String
        var floorValue: Double
        var sequence: Int
        var channel: String
        var country: String
        var dosageMg: Double
        var margin: Double
        var status: PendingResultMetricStatus

        init(code: String, label: String, externalRef: String, floorValue: Double, sequence: Int, channel: String, country: String, dosageMg: Double, margin: Double, status: PendingResultMetricStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.sequence = sequence
            self.channel = channel
            self.country = country
            self.dosageMg = dosageMg
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingResultMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PendingResultMetricStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingResultMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending result metric") \(code)"
        }

        func effectiveValue() -> Double {
            return (margin * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> PendingResultMetric {
            return PendingResultMetric(
                code: code,
                label: label,
                externalRef: externalRef,
                floorValue: floorValue,
                sequence: sequence,
                channel: channel,
                country: country,
                dosageMg: dosageMg,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending result metric in status open.
    static func newPendingResultMetric(_ code: String, label: String) -> PendingResultMetric {
        return PendingResultMetric(
            code: code,
            label: label,
            externalRef: "",
            floorValue: 0.0,
            sequence: 0,
            channel: "",
            country: "",
            dosageMg: 0.0,
            margin: 0.0,
            status: PendingResultMetricStatus.`open`
        )
    }
}
