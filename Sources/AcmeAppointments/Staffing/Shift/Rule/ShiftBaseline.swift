import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift baseline is in its life cycle.
    enum ShiftBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One shift baseline, with what the planners need to act on it.
    final class ShiftBaseline {
        var code: String
        var title: String
        var expiresAt: Int
        var attempts: Int
        var ownerID: String
        var pinned: Bool
        var retries: Int
        var maximum: Double
        var name: String
        var amount: Double
        var status: ShiftBaselineStatus

        init(code: String, title: String, expiresAt: Int, attempts: Int, ownerID: String, pinned: Bool, retries: Int, maximum: Double, name: String, amount: Double, status: ShiftBaselineStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.ownerID = ownerID
            self.pinned = pinned
            self.retries = retries
            self.maximum = maximum
            self.name = name
            self.amount = amount
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

        func canMoveTo(_ next: ShiftBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ShiftBaselineStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ShiftBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((amount - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftBaseline {
            return ShiftBaseline(
                code: code,
                title: title,
                expiresAt: expiresAt,
                attempts: attempts,
                ownerID: ownerID,
                pinned: pinned,
                retries: retries,
                maximum: maximum,
                name: name,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a shift baseline in status planned.
    static func newShiftBaseline(_ code: String, title: String) -> ShiftBaseline {
        return ShiftBaseline(
            code: code,
            title: title,
            expiresAt: 0,
            attempts: 0,
            ownerID: "",
            pinned: false,
            retries: 0,
            maximum: 0.0,
            name: "",
            amount: 0.0,
            status: ShiftBaselineStatus.planned
        )
    }
}
