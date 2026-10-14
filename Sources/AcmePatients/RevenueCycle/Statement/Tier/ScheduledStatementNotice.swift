import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled statement notice is in its life cycle.
    enum ScheduledStatementNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled statement notice as the statement team keeps it.
    final class ScheduledStatementNotice {
        var code: String
        var name: String
        var timezone: String
        var contactEmail: String
        var visitMinutes: Int
        var externalRef: String
        var phone: String
        var status: ScheduledStatementNoticeStatus

        init(code: String, name: String, timezone: String, contactEmail: String, visitMinutes: Int, externalRef: String, phone: String, status: ScheduledStatementNoticeStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.phone = phone
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

        func canMoveTo(_ next: ScheduledStatementNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledStatementNoticeStatus.pending || next == ScheduledStatementNoticeStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ScheduledStatementNoticeStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledStatementNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled statement notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled statement notice") \(code)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ScheduledStatementNotice {
            return ScheduledStatementNotice(
                code: code,
                name: name,
                timezone: timezone,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                externalRef: externalRef,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled statement notice in status draft.
    static func newScheduledStatementNotice(_ code: String, name: String) -> ScheduledStatementNotice {
        return ScheduledStatementNotice(
            code: code,
            name: name,
            timezone: "",
            contactEmail: "",
            visitMinutes: 0,
            externalRef: "",
            phone: "",
            status: ScheduledStatementNoticeStatus.draft
        )
    }
}
