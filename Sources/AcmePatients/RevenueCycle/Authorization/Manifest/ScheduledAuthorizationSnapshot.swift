import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled authorization snapshot is in its life cycle.
    enum ScheduledAuthorizationSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled authorization snapshot and its current status.
    final class ScheduledAuthorizationSnapshot {
        var code: String
        var title: String
        var payer: String
        var active: Bool
        var amount: Double
        var refills: Int
        var visible: Bool
        var status: ScheduledAuthorizationSnapshotStatus

        init(code: String, title: String, payer: String, active: Bool, amount: Double, refills: Int, visible: Bool, status: ScheduledAuthorizationSnapshotStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.active = active
            self.amount = amount
            self.refills = refills
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

        func canMoveTo(_ next: ScheduledAuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledAuthorizationSnapshotStatus.withdrawn
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

        func moveTo(_ next: ScheduledAuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(refills) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAuthorizationSnapshot {
            return ScheduledAuthorizationSnapshot(
                code: code,
                title: title,
                payer: payer,
                active: active,
                amount: amount,
                refills: refills,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled authorization snapshot in status proposed.
    static func newScheduledAuthorizationSnapshot(_ code: String, title: String) -> ScheduledAuthorizationSnapshot {
        return ScheduledAuthorizationSnapshot(
            code: code,
            title: title,
            payer: "",
            active: false,
            amount: 0.0,
            refills: 0,
            visible: false,
            status: ScheduledAuthorizationSnapshotStatus.proposed
        )
    }
}
