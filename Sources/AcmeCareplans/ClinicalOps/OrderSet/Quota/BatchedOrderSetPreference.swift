import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched order set preference is in its life cycle.
    enum BatchedOrderSetPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a batched order set preference and its current status.
    final class BatchedOrderSetPreference {
        var code: String
        var label: String
        var tags: [String]
        var quantity: Int
        var channel: String
        var status: BatchedOrderSetPreferenceStatus

        init(code: String, label: String, tags: [String], quantity: Int, channel: String, status: BatchedOrderSetPreferenceStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.quantity = quantity
            self.channel = channel
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

        func canMoveTo(_ next: BatchedOrderSetPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedOrderSetPreferenceStatus.withdrawn
            case .rejected:
                return next == BatchedOrderSetPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOrderSetPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched order set preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched order set preference") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> BatchedOrderSetPreference {
            return BatchedOrderSetPreference(
                code: code,
                label: label,
                tags: tags,
                quantity: quantity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched order set preference in status proposed.
    static func newBatchedOrderSetPreference(_ code: String, label: String) -> BatchedOrderSetPreference {
        return BatchedOrderSetPreference(
            code: code,
            label: label,
            tags: [],
            quantity: 0,
            channel: "",
            status: BatchedOrderSetPreferenceStatus.proposed
        )
    }
}
