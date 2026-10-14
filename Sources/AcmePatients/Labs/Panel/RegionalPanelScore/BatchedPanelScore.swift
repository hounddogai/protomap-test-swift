import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched panel score is in its life cycle.
    enum BatchedPanelScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched panel score, with what the planners need to act on it.
    final class BatchedPanelScore {
        var code: String
        var title: String
        var priority: Int
        var ceiling: Double
        var sequence: Int
        var status: BatchedPanelScoreStatus

        init(code: String, title: String, priority: Int, ceiling: Double, sequence: Int, status: BatchedPanelScoreStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.ceiling = ceiling
            self.sequence = sequence
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

        func canMoveTo(_ next: BatchedPanelScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedPanelScoreStatus.validated || next == BatchedPanelScoreStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedPanelScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedPanelScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched panel score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched panel score") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(sequence) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> BatchedPanelScore {
            return BatchedPanelScore(
                code: code,
                title: title,
                priority: priority,
                ceiling: ceiling,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched panel score in status created.
    static func newBatchedPanelScore(_ code: String, title: String) -> BatchedPanelScore {
        return BatchedPanelScore(
            code: code,
            title: title,
            priority: 0,
            ceiling: 0.0,
            sequence: 0,
            status: BatchedPanelScoreStatus.created
        )
    }
}
