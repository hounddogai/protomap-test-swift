import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff metric is in its life cycle.
    enum HandoffMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One handoff metric, with what the planners need to act on it.
    final class HandoffMetric {
        var code: String
        var label: String
        var notes: String
        var rate: Double
        var batchSize: Int
        var pinned: Bool
        var acuity: Int
        var ward: String
        var status: HandoffMetricStatus

        init(code: String, label: String, notes: String, rate: Double, batchSize: Int, pinned: Bool, acuity: Int, ward: String, status: HandoffMetricStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.rate = rate
            self.batchSize = batchSize
            self.pinned = pinned
            self.acuity = acuity
            self.ward = ward
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

        func canMoveTo(_ next: HandoffMetricStatus) -> Bool {
            switch status {
            case .proposed:
                return next == HandoffMetricStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: HandoffMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return (Double(acuity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> HandoffMetric {
            return HandoffMetric(
                code: code,
                label: label,
                notes: notes,
                rate: rate,
                batchSize: batchSize,
                pinned: pinned,
                acuity: acuity,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a handoff metric in status proposed.
    static func newHandoffMetric(_ code: String, label: String) -> HandoffMetric {
        return HandoffMetric(
            code: code,
            label: label,
            notes: "",
            rate: 0.0,
            batchSize: 0,
            pinned: false,
            acuity: 0,
            ward: "",
            status: HandoffMetricStatus.proposed
        )
    }
}
