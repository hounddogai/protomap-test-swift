import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending specimen metric is in its life cycle.
    enum PendingSpecimenMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending specimen metric. Its code is unique within a tenant.
    final class PendingSpecimenMetric {
        var code: String
        var label: String
        var copay: Double
        var sequence: Int
        var attempts: Int
        var graceDays: Int
        var acuity: Int
        var status: PendingSpecimenMetricStatus

        init(code: String, label: String, copay: Double, sequence: Int, attempts: Int, graceDays: Int, acuity: Int, status: PendingSpecimenMetricStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.sequence = sequence
            self.attempts = attempts
            self.graceDays = graceDays
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingSpecimenMetricStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PendingSpecimenMetricStatus.active || next == PendingSpecimenMetricStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PendingSpecimenMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSpecimenMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending specimen metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return (copay * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> PendingSpecimenMetric {
            return PendingSpecimenMetric(
                code: code,
                label: label,
                copay: copay,
                sequence: sequence,
                attempts: attempts,
                graceDays: graceDays,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending specimen metric in status draft.
    static func newPendingSpecimenMetric(_ code: String, label: String) -> PendingSpecimenMetric {
        return PendingSpecimenMetric(
            code: code,
            label: label,
            copay: 0.0,
            sequence: 0,
            attempts: 0,
            graceDays: 0,
            acuity: 0,
            status: PendingSpecimenMetricStatus.draft
        )
    }
}
