import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched read estimate is in its life cycle.
    enum BatchedReadEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched read estimate as the read team keeps it.
    final class BatchedReadEstimate {
        var code: String
        var label: String
        var source: String
        var segment: String
        var channel: String
        var score: Double
        var status: BatchedReadEstimateStatus

        init(code: String, label: String, source: String, segment: String, channel: String, score: Double, status: BatchedReadEstimateStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.segment = segment
            self.channel = channel
            self.score = score
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

        func canMoveTo(_ next: BatchedReadEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedReadEstimateStatus.rejected || next == BatchedReadEstimateStatus.withdrawn
            case .rejected:
                return next == BatchedReadEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReadEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched read estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedReadEstimate {
            return BatchedReadEstimate(
                code: code,
                label: label,
                source: source,
                segment: segment,
                channel: channel,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched read estimate in status proposed.
    static func newBatchedReadEstimate(_ code: String, label: String) -> BatchedReadEstimate {
        return BatchedReadEstimate(
            code: code,
            label: label,
            source: "",
            segment: "",
            channel: "",
            score: 0.0,
            status: BatchedReadEstimateStatus.proposed
        )
    }
}
