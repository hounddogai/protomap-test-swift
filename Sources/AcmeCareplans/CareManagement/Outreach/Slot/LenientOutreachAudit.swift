import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach audit is in its life cycle.
    enum LenientOutreachAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient outreach audit as the outreach team keeps it.
    final class LenientOutreachAudit {
        var code: String
        var title: String
        var ward: String
        var encounterID: String
        var externalRef: String
        var bed: String
        var expiresAt: Int
        var status: LenientOutreachAuditStatus

        init(code: String, title: String, ward: String, encounterID: String, externalRef: String, bed: String, expiresAt: Int, status: LenientOutreachAuditStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.encounterID = encounterID
            self.externalRef = externalRef
            self.bed = bed
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: LenientOutreachAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientOutreachAuditStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientOutreachAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientOutreachAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient outreach audit") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> LenientOutreachAudit {
            return LenientOutreachAudit(
                code: code,
                title: title,
                ward: ward,
                encounterID: encounterID,
                externalRef: externalRef,
                bed: bed,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient outreach audit in status requested.
    static func newLenientOutreachAudit(_ code: String, title: String) -> LenientOutreachAudit {
        return LenientOutreachAudit(
            code: code,
            title: title,
            ward: "",
            encounterID: "",
            externalRef: "",
            bed: "",
            expiresAt: 0,
            status: LenientOutreachAuditStatus.requested
        )
    }
}
