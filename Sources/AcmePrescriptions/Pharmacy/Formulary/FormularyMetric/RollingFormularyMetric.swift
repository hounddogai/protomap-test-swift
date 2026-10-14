import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling formulary metric is in its life cycle.
    enum RollingFormularyMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling formulary metric as the formulary team keeps it.
    final class RollingFormularyMetric {
        var code: String
        var title: String
        var graceDays: Int
        var threshold: Double
        var checksum: String
        var batchSize: Int
        var status: RollingFormularyMetricStatus

        init(code: String, title: String, graceDays: Int, threshold: Double, checksum: String, batchSize: Int, status: RollingFormularyMetricStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.threshold = threshold
            self.checksum = checksum
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RollingFormularyMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingFormularyMetricStatus.inProgress || next == RollingFormularyMetricStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RollingFormularyMetricStatus.cancelled
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

        func moveTo(_ next: RollingFormularyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling formulary metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((threshold + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingFormularyMetric {
            return RollingFormularyMetric(
                code: code,
                title: title,
                graceDays: graceDays,
                threshold: threshold,
                checksum: checksum,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling formulary metric in status planned.
    static func newRollingFormularyMetric(_ code: String, title: String) -> RollingFormularyMetric {
        return RollingFormularyMetric(
            code: code,
            title: title,
            graceDays: 0,
            threshold: 0.0,
            checksum: "",
            batchSize: 0,
            status: RollingFormularyMetricStatus.planned
        )
    }
}
