import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default dispense adjustment is in its life cycle.
    enum DefaultDispenseAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default dispense adjustment and its current status.
    final class DefaultDispenseAdjustment {
        var code: String
        var title: String
        var notes: String
        var limit: Int
        var retries: Int
        var status: DefaultDispenseAdjustmentStatus

        init(code: String, title: String, notes: String, limit: Int, retries: Int, status: DefaultDispenseAdjustmentStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.limit = limit
            self.retries = retries
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

        func canMoveTo(_ next: DefaultDispenseAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultDispenseAdjustmentStatus.completed
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

        func moveTo(_ next: DefaultDispenseAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default dispense adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return (Double(limit) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDispenseAdjustment {
            return DefaultDispenseAdjustment(
                code: code,
                title: title,
                notes: notes,
                limit: limit,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default dispense adjustment in status planned.
    static func newDefaultDispenseAdjustment(_ code: String, title: String) -> DefaultDispenseAdjustment {
        return DefaultDispenseAdjustment(
            code: code,
            title: title,
            notes: "",
            limit: 0,
            retries: 0,
            status: DefaultDispenseAdjustmentStatus.planned
        )
    }
}
