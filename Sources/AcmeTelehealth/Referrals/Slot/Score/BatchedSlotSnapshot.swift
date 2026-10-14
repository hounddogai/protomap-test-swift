import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot snapshot is in its life cycle.
    enum BatchedSlotSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched slot snapshot. Its code is unique within a tenant.
    final class BatchedSlotSnapshot {
        var code: String
        var title: String
        var priority: Int
        var channel: String
        var visible: Bool
        var attributes: [String: String]
        var amount: Double
        var status: BatchedSlotSnapshotStatus

        init(code: String, title: String, priority: Int, channel: String, visible: Bool, attributes: [String: String], amount: Double, status: BatchedSlotSnapshotStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.channel = channel
            self.visible = visible
            self.attributes = attributes
            self.amount = amount
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

        func canMoveTo(_ next: BatchedSlotSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedSlotSnapshotStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedSlotSnapshotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSlotSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + amount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotSnapshot {
            return BatchedSlotSnapshot(
                code: code,
                title: title,
                priority: priority,
                channel: channel,
                visible: visible,
                attributes: attributes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched slot snapshot in status planned.
    static func newBatchedSlotSnapshot(_ code: String, title: String) -> BatchedSlotSnapshot {
        return BatchedSlotSnapshot(
            code: code,
            title: title,
            priority: 0,
            channel: "",
            visible: false,
            attributes: [:],
            amount: 0.0,
            status: BatchedSlotSnapshotStatus.planned
        )
    }
}
