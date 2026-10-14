import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up rollup is in its life cycle.
    enum FollowUpRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A follow up rollup. Its code is unique within a tenant.
    final class FollowUpRollup {
        var code: String
        var title: String
        var name: String
        var pinned: Bool
        var reviewer: String
        var notes: String
        var quantity: Int
        var visible: Bool
        var status: FollowUpRollupStatus

        init(code: String, title: String, name: String, pinned: Bool, reviewer: String, notes: String, quantity: Int, visible: Bool, status: FollowUpRollupStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.pinned = pinned
            self.reviewer = reviewer
            self.notes = notes
            self.quantity = quantity
            self.visible = visible
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

        func canMoveTo(_ next: FollowUpRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FollowUpRollupStatus.approved || next == FollowUpRollupStatus.withdrawn
            case .approved:
                return next == FollowUpRollupStatus.rejected
            case .rejected:
                return next == FollowUpRollupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> FollowUpRollup {
            return FollowUpRollup(
                code: code,
                title: title,
                name: name,
                pinned: pinned,
                reviewer: reviewer,
                notes: notes,
                quantity: quantity,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up rollup in status proposed.
    static func newFollowUpRollup(_ code: String, title: String) -> FollowUpRollup {
        return FollowUpRollup(
            code: code,
            title: title,
            name: "",
            pinned: false,
            reviewer: "",
            notes: "",
            quantity: 0,
            visible: false,
            status: FollowUpRollupStatus.proposed
        )
    }
}
