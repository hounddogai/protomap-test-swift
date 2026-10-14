import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling authorization snapshot is in its life cycle.
    enum RollingAuthorizationSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a rolling authorization snapshot and its current status.
    final class RollingAuthorizationSnapshot {
        var code: String
        var name: String
        var visible: Bool
        var patientRef: String
        var archived: Bool
        var amount: Double
        var status: RollingAuthorizationSnapshotStatus

        init(code: String, name: String, visible: Bool, patientRef: String, archived: Bool, amount: Double, status: RollingAuthorizationSnapshotStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.patientRef = patientRef
            self.archived = archived
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingAuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingAuthorizationSnapshotStatus.reopened || next == RollingAuthorizationSnapshotStatus.archived
            case .resolved:
                return next == RollingAuthorizationSnapshotStatus.reopened || next == RollingAuthorizationSnapshotStatus.archived
            case .reopened:
                return next == RollingAuthorizationSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingAuthorizationSnapshot {
            return RollingAuthorizationSnapshot(
                code: code,
                name: name,
                visible: visible,
                patientRef: patientRef,
                archived: archived,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling authorization snapshot in status open.
    static func newRollingAuthorizationSnapshot(_ code: String, name: String) -> RollingAuthorizationSnapshot {
        return RollingAuthorizationSnapshot(
            code: code,
            name: name,
            visible: false,
            patientRef: "",
            archived: false,
            amount: 0.0,
            status: RollingAuthorizationSnapshotStatus.`open`
        )
    }
}
