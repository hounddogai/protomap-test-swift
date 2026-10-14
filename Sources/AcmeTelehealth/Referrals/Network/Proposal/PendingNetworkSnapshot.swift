import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network snapshot is in its life cycle.
    enum PendingNetworkSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending network snapshot, with what the planners need to act on it.
    final class PendingNetworkSnapshot {
        var code: String
        var title: String
        var ceiling: Double
        var capacity: Int
        var channel: String
        var status: PendingNetworkSnapshotStatus

        init(code: String, title: String, ceiling: Double, capacity: Int, channel: String, status: PendingNetworkSnapshotStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingNetworkSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingNetworkSnapshotStatus.approved
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

        func moveTo(_ next: PendingNetworkSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending network snapshot") \(code)"
        }

        func adjustedValue() -> Double {
            return (ceiling * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PendingNetworkSnapshot {
            return PendingNetworkSnapshot(
                code: code,
                title: title,
                ceiling: ceiling,
                capacity: capacity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending network snapshot in status proposed.
    static func newPendingNetworkSnapshot(_ code: String, title: String) -> PendingNetworkSnapshot {
        return PendingNetworkSnapshot(
            code: code,
            title: title,
            ceiling: 0.0,
            capacity: 0,
            channel: "",
            status: PendingNetworkSnapshotStatus.proposed
        )
    }
}
