import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift snapshot is in its life cycle.
    enum ShiftSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A shift snapshot as the shift team keeps it.
    final class ShiftSnapshot {
        var code: String
        var name: String
        var ownerID: String
        var expiresAt: Int
        var phone: String
        var notes: String
        var sequence: Int
        var status: ShiftSnapshotStatus

        init(code: String, name: String, ownerID: String, expiresAt: Int, phone: String, notes: String, sequence: Int, status: ShiftSnapshotStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.expiresAt = expiresAt
            self.phone = phone
            self.notes = notes
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftSnapshotStatus.cancelled
            case .scheduled:
                return next == ShiftSnapshotStatus.cancelled
            case .inProgress:
                return next == ShiftSnapshotStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ShiftSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((Double(sequence) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftSnapshot {
            return ShiftSnapshot(
                code: code,
                name: name,
                ownerID: ownerID,
                expiresAt: expiresAt,
                phone: phone,
                notes: notes,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift snapshot in status planned.
    static func newShiftSnapshot(_ code: String, name: String) -> ShiftSnapshot {
        return ShiftSnapshot(
            code: code,
            name: name,
            ownerID: "",
            expiresAt: 0,
            phone: "",
            notes: "",
            sequence: 0,
            status: ShiftSnapshotStatus.planned
        )
    }
}
