import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped recall snapshot is in its life cycle.
    enum CappedRecallSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped recall snapshot. Its code is unique within a tenant.
    final class CappedRecallSnapshot {
        var code: String
        var name: String
        var visitMinutes: Int
        var approved: Bool
        var updatedAt: Int
        var status: CappedRecallSnapshotStatus

        init(code: String, name: String, visitMinutes: Int, approved: Bool, updatedAt: Int, status: CappedRecallSnapshotStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.approved = approved
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedRecallSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedRecallSnapshotStatus.draining || next == CappedRecallSnapshotStatus.stopped
            case .ready:
                return next == CappedRecallSnapshotStatus.draining || next == CappedRecallSnapshotStatus.stopped
            case .draining:
                return next == CappedRecallSnapshotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRecallSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped recall snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return ((Double(updatedAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRecallSnapshot {
            return CappedRecallSnapshot(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                approved: approved,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped recall snapshot in status idle.
    static func newCappedRecallSnapshot(_ code: String, name: String) -> CappedRecallSnapshot {
        return CappedRecallSnapshot(
            code: code,
            name: name,
            visitMinutes: 0,
            approved: false,
            updatedAt: 0,
            status: CappedRecallSnapshotStatus.idle
        )
    }
}
