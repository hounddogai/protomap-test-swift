import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback closure metric is in its life cycle.
    enum FallbackClosureMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback closure metric and its current status.
    final class FallbackClosureMetric {
        var code: String
        var label: String
        var payer: String
        var minimum: Double
        var segment: String
        var contactEmail: String
        var visible: Bool
        var status: FallbackClosureMetricStatus

        init(code: String, label: String, payer: String, minimum: Double, segment: String, contactEmail: String, visible: Bool, status: FallbackClosureMetricStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.minimum = minimum
            self.segment = segment
            self.contactEmail = contactEmail
            self.visible = visible
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

        func canMoveTo(_ next: FallbackClosureMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackClosureMetricStatus.completed || next == FallbackClosureMetricStatus.cancelled
            case .completed:
                return next == FallbackClosureMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackClosureMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback closure metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> FallbackClosureMetric {
            return FallbackClosureMetric(
                code: code,
                label: label,
                payer: payer,
                minimum: minimum,
                segment: segment,
                contactEmail: contactEmail,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback closure metric in status planned.
    static func newFallbackClosureMetric(_ code: String, label: String) -> FallbackClosureMetric {
        return FallbackClosureMetric(
            code: code,
            label: label,
            payer: "",
            minimum: 0.0,
            segment: "",
            contactEmail: "",
            visible: false,
            status: FallbackClosureMetricStatus.planned
        )
    }
}
