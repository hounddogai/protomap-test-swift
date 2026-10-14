import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default outreach audit is in its life cycle.
    enum DefaultOutreachAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default outreach audit. Its code is unique within a tenant.
    final class DefaultOutreachAudit {
        var code: String
        var title: String
        var pinned: Bool
        var archived: Bool
        var sequence: Int
        var procedureCode: String
        var contactEmail: String
        var region: String
        var status: DefaultOutreachAuditStatus

        init(code: String, title: String, pinned: Bool, archived: Bool, sequence: Int, procedureCode: String, contactEmail: String, region: String, status: DefaultOutreachAuditStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.archived = archived
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultOutreachAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultOutreachAuditStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultOutreachAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultOutreachAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default outreach audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default outreach audit") \(code)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> DefaultOutreachAudit {
            return DefaultOutreachAudit(
                code: code,
                title: title,
                pinned: pinned,
                archived: archived,
                sequence: sequence,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default outreach audit in status requested.
    static func newDefaultOutreachAudit(_ code: String, title: String) -> DefaultOutreachAudit {
        return DefaultOutreachAudit(
            code: code,
            title: title,
            pinned: false,
            archived: false,
            sequence: 0,
            procedureCode: "",
            contactEmail: "",
            region: "",
            status: DefaultOutreachAuditStatus.requested
        )
    }
}
