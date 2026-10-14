import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program audit is in its life cycle.
    enum ProgramAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program audit, with what the planners need to act on it.
    final class ProgramAudit {
        var code: String
        var name: String
        var payer: String
        var category: String
        var encounterID: String
        var retries: Int
        var procedureCode: String
        var amount: Double
        var reviewer: String
        var title: String
        var status: ProgramAuditStatus

        init(code: String, name: String, payer: String, category: String, encounterID: String, retries: Int, procedureCode: String, amount: Double, reviewer: String, title: String, status: ProgramAuditStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.category = category
            self.encounterID = encounterID
            self.retries = retries
            self.procedureCode = procedureCode
            self.amount = amount
            self.reviewer = reviewer
            self.title = title
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

        func canMoveTo(_ next: ProgramAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramAuditStatus.active || next == ProgramAuditStatus.closed
            case .pending:
                return next == ProgramAuditStatus.suspended || next == ProgramAuditStatus.closed
            case .active:
                return next == ProgramAuditStatus.closed
            case .suspended:
                return next == ProgramAuditStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(retries) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ProgramAudit {
            return ProgramAudit(
                code: code,
                name: name,
                payer: payer,
                category: category,
                encounterID: encounterID,
                retries: retries,
                procedureCode: procedureCode,
                amount: amount,
                reviewer: reviewer,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a program audit in status draft.
    static func newProgramAudit(_ code: String, name: String) -> ProgramAudit {
        return ProgramAudit(
            code: code,
            name: name,
            payer: "",
            category: "",
            encounterID: "",
            retries: 0,
            procedureCode: "",
            amount: 0.0,
            reviewer: "",
            title: "",
            status: ProgramAuditStatus.draft
        )
    }
}
