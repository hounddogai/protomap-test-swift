import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped overtime mapping is in its life cycle.
    enum CappedOvertimeMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped overtime mapping. Its code is unique within a tenant.
    final class CappedOvertimeMapping {
        var code: String
        var name: String
        var timezone: String
        var ownerID: String
        var budget: Double
        var expiresAt: Int
        var unit: String
        var procedureCode: String
        var patientRef: String
        var graceDays: Int
        var status: CappedOvertimeMappingStatus

        init(code: String, name: String, timezone: String, ownerID: String, budget: Double, expiresAt: Int, unit: String, procedureCode: String, patientRef: String, graceDays: Int, status: CappedOvertimeMappingStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.ownerID = ownerID
            self.budget = budget
            self.expiresAt = expiresAt
            self.unit = unit
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CappedOvertimeMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedOvertimeMappingStatus.pending || next == CappedOvertimeMappingStatus.suspended
            case .pending:
                return next == CappedOvertimeMappingStatus.active
            case .active:
                return next == CappedOvertimeMappingStatus.closed
            case .suspended:
                return next == CappedOvertimeMappingStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedOvertimeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped overtime mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((budget - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedOvertimeMapping {
            return CappedOvertimeMapping(
                code: code,
                name: name,
                timezone: timezone,
                ownerID: ownerID,
                budget: budget,
                expiresAt: expiresAt,
                unit: unit,
                procedureCode: procedureCode,
                patientRef: patientRef,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped overtime mapping in status draft.
    static func newCappedOvertimeMapping(_ code: String, name: String) -> CappedOvertimeMapping {
        return CappedOvertimeMapping(
            code: code,
            name: name,
            timezone: "",
            ownerID: "",
            budget: 0.0,
            expiresAt: 0,
            unit: "",
            procedureCode: "",
            patientRef: "",
            graceDays: 0,
            status: CappedOvertimeMappingStatus.draft
        )
    }
}
