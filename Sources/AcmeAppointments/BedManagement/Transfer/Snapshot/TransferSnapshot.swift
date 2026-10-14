import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer snapshot is in its life cycle.
    enum TransferSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One transfer snapshot, with what the planners need to act on it.
    final class TransferSnapshot {
        var code: String
        var name: String
        var reviewer: String
        var ownerID: String
        var approved: Bool
        var quantity: Int
        var status: TransferSnapshotStatus

        init(code: String, name: String, reviewer: String, ownerID: String, approved: Bool, quantity: Int, status: TransferSnapshotStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.approved = approved
            self.quantity = quantity
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

        func canMoveTo(_ next: TransferSnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TransferSnapshotStatus.published || next == TransferSnapshotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TransferSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TransferSnapshot {
            return TransferSnapshot(
                code: code,
                name: name,
                reviewer: reviewer,
                ownerID: ownerID,
                approved: approved,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer snapshot in status created.
    static func newTransferSnapshot(_ code: String, name: String) -> TransferSnapshot {
        return TransferSnapshot(
            code: code,
            name: name,
            reviewer: "",
            ownerID: "",
            approved: false,
            quantity: 0,
            status: TransferSnapshotStatus.created
        )
    }
}
