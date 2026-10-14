import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling care protocol audit is in its life cycle.
    enum RollingCareProtocolAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rolling care protocol audit and its current status.
    final class RollingCareProtocolAudit {
        var code: String
        var label: String
        var windowDays: Int
        var approved: Bool
        var procedureCode: String
        var facility: String
        var status: RollingCareProtocolAuditStatus

        init(code: String, label: String, windowDays: Int, approved: Bool, procedureCode: String, facility: String, status: RollingCareProtocolAuditStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.approved = approved
            self.procedureCode = procedureCode
            self.facility = facility
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

        func canMoveTo(_ next: RollingCareProtocolAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingCareProtocolAuditStatus.suspended || next == RollingCareProtocolAuditStatus.closed
            case .pending:
                return next == RollingCareProtocolAuditStatus.closed
            case .active:
                return next == RollingCareProtocolAuditStatus.suspended || next == RollingCareProtocolAuditStatus.closed
            case .suspended:
                return next == RollingCareProtocolAuditStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling care protocol audit") \(code)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> RollingCareProtocolAudit {
            return RollingCareProtocolAudit(
                code: code,
                label: label,
                windowDays: windowDays,
                approved: approved,
                procedureCode: procedureCode,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling care protocol audit in status draft.
    static func newRollingCareProtocolAudit(_ code: String, label: String) -> RollingCareProtocolAudit {
        return RollingCareProtocolAudit(
            code: code,
            label: label,
            windowDays: 0,
            approved: false,
            procedureCode: "",
            facility: "",
            status: RollingCareProtocolAuditStatus.draft
        )
    }
}
