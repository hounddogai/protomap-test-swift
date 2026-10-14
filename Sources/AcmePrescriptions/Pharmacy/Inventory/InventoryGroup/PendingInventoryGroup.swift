import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending inventory group is in its life cycle.
    enum PendingInventoryGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending inventory group and its current status.
    final class PendingInventoryGroup {
        var code: String
        var title: String
        var pinned: Bool
        var limit: Int
        var bed: String
        var status: PendingInventoryGroupStatus

        init(code: String, title: String, pinned: Bool, limit: Int, bed: String, status: PendingInventoryGroupStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.limit = limit
            self.bed = bed
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

        func canMoveTo(_ next: PendingInventoryGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingInventoryGroupStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingInventoryGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingInventoryGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending inventory group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending inventory group") \(code)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> PendingInventoryGroup {
            return PendingInventoryGroup(
                code: code,
                title: title,
                pinned: pinned,
                limit: limit,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending inventory group in status proposed.
    static func newPendingInventoryGroup(_ code: String, title: String) -> PendingInventoryGroup {
        return PendingInventoryGroup(
            code: code,
            title: title,
            pinned: false,
            limit: 0,
            bed: "",
            status: PendingInventoryGroupStatus.proposed
        )
    }
}
