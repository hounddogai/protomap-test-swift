import AcmePlatform
import Foundation

extension Labs {
    /// Where a default result audit is in its life cycle.
    enum DefaultResultAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One default result audit, with what the planners need to act on it.
    final class DefaultResultAudit {
        var code: String
        var title: String
        var approved: Bool
        var startsAt: Int
        var copay: Double
        var pinned: Bool
        var timezone: String
        var expiresAt: Int
        var ratio: Double
        var status: DefaultResultAuditStatus

        init(code: String, title: String, approved: Bool, startsAt: Int, copay: Double, pinned: Bool, timezone: String, expiresAt: Int, ratio: Double, status: DefaultResultAuditStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.startsAt = startsAt
            self.copay = copay
            self.pinned = pinned
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.ratio = ratio
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

        func canMoveTo(_ next: DefaultResultAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultResultAuditStatus.active || next == DefaultResultAuditStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DefaultResultAuditStatus.closed
            case .suspended:
                return next == DefaultResultAuditStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultResultAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default result audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((copay - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultResultAudit {
            return DefaultResultAudit(
                code: code,
                title: title,
                approved: approved,
                startsAt: startsAt,
                copay: copay,
                pinned: pinned,
                timezone: timezone,
                expiresAt: expiresAt,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default result audit in status draft.
    static func newDefaultResultAudit(_ code: String, title: String) -> DefaultResultAudit {
        return DefaultResultAudit(
            code: code,
            title: title,
            approved: false,
            startsAt: 0,
            copay: 0.0,
            pinned: false,
            timezone: "",
            expiresAt: 0,
            ratio: 0.0,
            status: DefaultResultAuditStatus.draft
        )
    }
}
