import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched rounding metric is in its life cycle.
    enum BatchedRoundingMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched rounding metric, with what the planners need to act on it.
    final class BatchedRoundingMetric {
        var code: String
        var label: String
        var version: Int
        var currency: String
        var archived: Bool
        var status: BatchedRoundingMetricStatus

        init(code: String, label: String, version: Int, currency: String, archived: Bool, status: BatchedRoundingMetricStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.currency = currency
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedRoundingMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedRoundingMetricStatus.revoked
            case .revoked:
                return next == BatchedRoundingMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRoundingMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched rounding metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> BatchedRoundingMetric {
            return BatchedRoundingMetric(
                code: code,
                label: label,
                version: version,
                currency: currency,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched rounding metric in status requested.
    static func newBatchedRoundingMetric(_ code: String, label: String) -> BatchedRoundingMetric {
        return BatchedRoundingMetric(
            code: code,
            label: label,
            version: 0,
            currency: "",
            archived: false,
            status: BatchedRoundingMetricStatus.requested
        )
    }
}
