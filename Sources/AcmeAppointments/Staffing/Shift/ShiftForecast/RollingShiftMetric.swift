import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling shift metric is in its life cycle.
    enum RollingShiftMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling shift metric. Its code is unique within a tenant.
    final class RollingShiftMetric {
        var code: String
        var label: String
        var contactEmail: String
        var amount: Double
        var revision: Int
        var status: RollingShiftMetricStatus

        init(code: String, label: String, contactEmail: String, amount: Double, revision: Int, status: RollingShiftMetricStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.amount = amount
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingShiftMetricStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingShiftMetricStatus.retired
            case .validated:
                return next == RollingShiftMetricStatus.published || next == RollingShiftMetricStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingShiftMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling shift metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return (amount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RollingShiftMetric {
            return RollingShiftMetric(
                code: code,
                label: label,
                contactEmail: contactEmail,
                amount: amount,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling shift metric in status created.
    static func newRollingShiftMetric(_ code: String, label: String) -> RollingShiftMetric {
        return RollingShiftMetric(
            code: code,
            label: label,
            contactEmail: "",
            amount: 0.0,
            revision: 0,
            status: RollingShiftMetricStatus.created
        )
    }
}
