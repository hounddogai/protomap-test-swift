import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol audit is in its life cycle.
    enum CareProtocolAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol audit as the care protocol team keeps it.
    final class CareProtocolAudit {
        var code: String
        var title: String
        var description: String
        var dosageMg: Double
        var clinicianID: String
        var graceDays: Int
        var attempts: Int
        var status: CareProtocolAuditStatus

        init(code: String, title: String, description: String, dosageMg: Double, clinicianID: String, graceDays: Int, attempts: Int, status: CareProtocolAuditStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.attempts = attempts
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

        func canMoveTo(_ next: CareProtocolAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolAuditStatus.pending || next == CareProtocolAuditStatus.suspended
            case .pending:
                return next == CareProtocolAuditStatus.suspended || next == CareProtocolAuditStatus.closed
            case .active:
                return next == CareProtocolAuditStatus.suspended || next == CareProtocolAuditStatus.closed
            case .suspended:
                return next == CareProtocolAuditStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return (Double(attempts) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAudit {
            return CareProtocolAudit(
                code: code,
                title: title,
                description: description,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                graceDays: graceDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol audit in status draft.
    static func newCareProtocolAudit(_ code: String, title: String) -> CareProtocolAudit {
        return CareProtocolAudit(
            code: code,
            title: title,
            description: "",
            dosageMg: 0.0,
            clinicianID: "",
            graceDays: 0,
            attempts: 0,
            status: CareProtocolAuditStatus.draft
        )
    }
}
