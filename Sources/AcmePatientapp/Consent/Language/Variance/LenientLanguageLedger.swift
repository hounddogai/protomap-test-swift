import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient language ledger is in its life cycle.
    enum LenientLanguageLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient language ledger. Its code is unique within a tenant.
    final class LenientLanguageLedger {
        var code: String
        var title: String
        var archived: Bool
        var channel: String
        var active: Bool
        var updatedAt: Int
        var capacity: Int
        var status: LenientLanguageLedgerStatus

        init(code: String, title: String, archived: Bool, channel: String, active: Bool, updatedAt: Int, capacity: Int, status: LenientLanguageLedgerStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.channel = channel
            self.active = active
            self.updatedAt = updatedAt
            self.capacity = capacity
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

        func canMoveTo(_ next: LenientLanguageLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LenientLanguageLedgerStatus.suspended
            case .active:
                return next == LenientLanguageLedgerStatus.closed
            case .suspended:
                return next == LenientLanguageLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientLanguageLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient language ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(updatedAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientLanguageLedger {
            return LenientLanguageLedger(
                code: code,
                title: title,
                archived: archived,
                channel: channel,
                active: active,
                updatedAt: updatedAt,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient language ledger in status draft.
    static func newLenientLanguageLedger(_ code: String, title: String) -> LenientLanguageLedger {
        return LenientLanguageLedger(
            code: code,
            title: title,
            archived: false,
            channel: "",
            active: false,
            updatedAt: 0,
            capacity: 0,
            status: LenientLanguageLedgerStatus.draft
        )
    }
}
