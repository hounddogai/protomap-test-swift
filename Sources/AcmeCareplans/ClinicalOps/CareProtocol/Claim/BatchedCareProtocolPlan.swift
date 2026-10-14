import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched care protocol plan is in its life cycle.
    enum BatchedCareProtocolPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched care protocol plan, with what the planners need to act on it.
    final class BatchedCareProtocolPlan {
        var code: String
        var label: String
        var channel: String
        var graceDays: Int
        var sequence: Int
        var title: String
        var rate: Double
        var visible: Bool
        var status: BatchedCareProtocolPlanStatus

        init(code: String, label: String, channel: String, graceDays: Int, sequence: Int, title: String, rate: Double, visible: Bool, status: BatchedCareProtocolPlanStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.graceDays = graceDays
            self.sequence = sequence
            self.title = title
            self.rate = rate
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

        func canMoveTo(_ next: BatchedCareProtocolPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedCareProtocolPlanStatus.completed || next == BatchedCareProtocolPlanStatus.cancelled
            case .scheduled:
                return next == BatchedCareProtocolPlanStatus.inProgress || next == BatchedCareProtocolPlanStatus.completed
            case .inProgress:
                return next == BatchedCareProtocolPlanStatus.completed || next == BatchedCareProtocolPlanStatus.cancelled
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

        func moveTo(_ next: BatchedCareProtocolPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched care protocol plan") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(sequence) - rate) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolPlan {
            return BatchedCareProtocolPlan(
                code: code,
                label: label,
                channel: channel,
                graceDays: graceDays,
                sequence: sequence,
                title: title,
                rate: rate,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched care protocol plan in status planned.
    static func newBatchedCareProtocolPlan(_ code: String, label: String) -> BatchedCareProtocolPlan {
        return BatchedCareProtocolPlan(
            code: code,
            label: label,
            channel: "",
            graceDays: 0,
            sequence: 0,
            title: "",
            rate: 0.0,
            visible: false,
            status: BatchedCareProtocolPlanStatus.planned
        )
    }
}
