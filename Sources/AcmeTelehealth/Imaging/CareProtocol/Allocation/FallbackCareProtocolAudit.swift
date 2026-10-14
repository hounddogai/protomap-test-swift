import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback care protocol audit is in its life cycle.
    enum FallbackCareProtocolAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback care protocol audit. Its code is unique within a tenant.
    final class FallbackCareProtocolAudit {
        var code: String
        var title: String
        var endsAt: Int
        var archived: Bool
        var name: String
        var approved: Bool
        var timezone: String
        var sequence: Int
        var externalRef: String
        var status: FallbackCareProtocolAuditStatus

        init(code: String, title: String, endsAt: Int, archived: Bool, name: String, approved: Bool, timezone: String, sequence: Int, externalRef: String, status: FallbackCareProtocolAuditStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.archived = archived
            self.name = name
            self.approved = approved
            self.timezone = timezone
            self.sequence = sequence
            self.externalRef = externalRef
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

        func canMoveTo(_ next: FallbackCareProtocolAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FallbackCareProtocolAuditStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FallbackCareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return (Double(endsAt) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolAudit {
            return FallbackCareProtocolAudit(
                code: code,
                title: title,
                endsAt: endsAt,
                archived: archived,
                name: name,
                approved: approved,
                timezone: timezone,
                sequence: sequence,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback care protocol audit in status draft.
    static func newFallbackCareProtocolAudit(_ code: String, title: String) -> FallbackCareProtocolAudit {
        return FallbackCareProtocolAudit(
            code: code,
            title: title,
            endsAt: 0,
            archived: false,
            name: "",
            approved: false,
            timezone: "",
            sequence: 0,
            externalRef: "",
            status: FallbackCareProtocolAuditStatus.draft
        )
    }
}
