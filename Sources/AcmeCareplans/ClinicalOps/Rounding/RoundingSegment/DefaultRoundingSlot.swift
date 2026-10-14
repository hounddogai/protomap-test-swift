import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default rounding slot is in its life cycle.
    enum DefaultRoundingSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One default rounding slot, with what the planners need to act on it.
    final class DefaultRoundingSlot {
        var code: String
        var title: String
        var timezone: String
        var expiresAt: Int
        var archived: Bool
        var status: DefaultRoundingSlotStatus

        init(code: String, title: String, timezone: String, expiresAt: Int, archived: Bool, status: DefaultRoundingSlotStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRoundingSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultRoundingSlotStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DefaultRoundingSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> DefaultRoundingSlot {
            return DefaultRoundingSlot(
                code: code,
                title: title,
                timezone: timezone,
                expiresAt: expiresAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default rounding slot in status draft.
    static func newDefaultRoundingSlot(_ code: String, title: String) -> DefaultRoundingSlot {
        return DefaultRoundingSlot(
            code: code,
            title: title,
            timezone: "",
            expiresAt: 0,
            archived: false,
            status: DefaultRoundingSlotStatus.draft
        )
    }
}
