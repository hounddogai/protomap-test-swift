import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift batch is in its life cycle.
    enum ShiftBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One shift batch, with what the planners need to act on it.
    final class ShiftBatch {
        var code: String
        var name: String
        var pinned: Bool
        var endsAt: Int
        var visitMinutes: Int
        var title: String
        var status: ShiftBatchStatus

        init(code: String, name: String, pinned: Bool, endsAt: Int, visitMinutes: Int, title: String, status: ShiftBatchStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.endsAt = endsAt
            self.visitMinutes = visitMinutes
            self.title = title
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

        func canMoveTo(_ next: ShiftBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftBatchStatus.inProgress || next == ShiftBatchStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ShiftBatchStatus.completed || next == ShiftBatchStatus.cancelled
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

        func moveTo(_ next: ShiftBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("shift batch") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(endsAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftBatch {
            return ShiftBatch(
                code: code,
                name: name,
                pinned: pinned,
                endsAt: endsAt,
                visitMinutes: visitMinutes,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift batch in status planned.
    static func newShiftBatch(_ code: String, name: String) -> ShiftBatch {
        return ShiftBatch(
            code: code,
            name: name,
            pinned: false,
            endsAt: 0,
            visitMinutes: 0,
            title: "",
            status: ShiftBatchStatus.planned
        )
    }
}
