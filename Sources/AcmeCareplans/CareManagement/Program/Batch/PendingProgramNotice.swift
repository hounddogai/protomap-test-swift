import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending program notice is in its life cycle.
    enum PendingProgramNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending program notice. Its code is unique within a tenant.
    final class PendingProgramNotice {
        var code: String
        var name: String
        var margin: Double
        var label: String
        var procedureCode: String
        var notes: String
        var status: PendingProgramNoticeStatus

        init(code: String, name: String, margin: Double, label: String, procedureCode: String, notes: String, status: PendingProgramNoticeStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.label = label
            self.procedureCode = procedureCode
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingProgramNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingProgramNoticeStatus.rejected || next == PendingProgramNoticeStatus.withdrawn
            case .approved:
                return next == PendingProgramNoticeStatus.withdrawn
            case .rejected:
                return next == PendingProgramNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingProgramNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending program notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending program notice") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> PendingProgramNotice {
            return PendingProgramNotice(
                code: code,
                name: name,
                margin: margin,
                label: label,
                procedureCode: procedureCode,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending program notice in status proposed.
    static func newPendingProgramNotice(_ code: String, name: String) -> PendingProgramNotice {
        return PendingProgramNotice(
            code: code,
            name: name,
            margin: 0.0,
            label: "",
            procedureCode: "",
            notes: "",
            status: PendingProgramNoticeStatus.proposed
        )
    }
}
