import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory snapshot is in its life cycle.
    enum ScheduledInventorySnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled inventory snapshot. Its code is unique within a tenant.
    final class ScheduledInventorySnapshot {
        var code: String
        var title: String
        var limit: Int
        var archived: Bool
        var visitMinutes: Int
        var refills: Int
        var status: ScheduledInventorySnapshotStatus

        init(code: String, title: String, limit: Int, archived: Bool, visitMinutes: Int, refills: Int, status: ScheduledInventorySnapshotStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.refills = refills
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

        func canMoveTo(_ next: ScheduledInventorySnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledInventorySnapshotStatus.expired
            case .granted:
                return next == ScheduledInventorySnapshotStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ScheduledInventorySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledInventorySnapshot {
            return ScheduledInventorySnapshot(
                code: code,
                title: title,
                limit: limit,
                archived: archived,
                visitMinutes: visitMinutes,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled inventory snapshot in status requested.
    static func newScheduledInventorySnapshot(_ code: String, title: String) -> ScheduledInventorySnapshot {
        return ScheduledInventorySnapshot(
            code: code,
            title: title,
            limit: 0,
            archived: false,
            visitMinutes: 0,
            refills: 0,
            status: ScheduledInventorySnapshotStatus.requested
        )
    }
}
