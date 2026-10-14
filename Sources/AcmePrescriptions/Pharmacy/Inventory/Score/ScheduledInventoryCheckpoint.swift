import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory checkpoint is in its life cycle.
    enum ScheduledInventoryCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a scheduled inventory checkpoint and its current status.
    final class ScheduledInventoryCheckpoint {
        var code: String
        var label: String
        var priority: Int
        var graceDays: Int
        var payer: String
        var capacity: Int
        var status: ScheduledInventoryCheckpointStatus

        init(code: String, label: String, priority: Int, graceDays: Int, payer: String, capacity: Int, status: ScheduledInventoryCheckpointStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.graceDays = graceDays
            self.payer = payer
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledInventoryCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledInventoryCheckpointStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ScheduledInventoryCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledInventoryCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((Double(capacity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledInventoryCheckpoint {
            return ScheduledInventoryCheckpoint(
                code: code,
                label: label,
                priority: priority,
                graceDays: graceDays,
                payer: payer,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled inventory checkpoint in status requested.
    static func newScheduledInventoryCheckpoint(_ code: String, label: String) -> ScheduledInventoryCheckpoint {
        return ScheduledInventoryCheckpoint(
            code: code,
            label: label,
            priority: 0,
            graceDays: 0,
            payer: "",
            capacity: 0,
            status: ScheduledInventoryCheckpointStatus.requested
        )
    }
}
