import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read batch is in its life cycle.
    enum ReadBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One read batch, with what the planners need to act on it.
    final class ReadBatch {
        var code: String
        var name: String
        var attempts: Int
        var capacity: Int
        var segment: String
        var pinned: Bool
        var status: ReadBatchStatus

        init(code: String, name: String, attempts: Int, capacity: Int, segment: String, pinned: Bool, status: ReadBatchStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.capacity = capacity
            self.segment = segment
            self.pinned = pinned
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

        func canMoveTo(_ next: ReadBatchStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ReadBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("read batch") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ReadBatch {
            return ReadBatch(
                code: code,
                name: name,
                attempts: attempts,
                capacity: capacity,
                segment: segment,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read batch in status proposed.
    static func newReadBatch(_ code: String, name: String) -> ReadBatch {
        return ReadBatch(
            code: code,
            name: name,
            attempts: 0,
            capacity: 0,
            segment: "",
            pinned: false,
            status: ReadBatchStatus.proposed
        )
    }
}
