import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense batch is in its life cycle.
    enum DispenseBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a dispense batch and its current status.
    final class DispenseBatch {
        var code: String
        var title: String
        var durationMinutes: Int
        var acuity: Int
        var budget: Double
        var clinicianID: String
        var status: DispenseBatchStatus

        init(code: String, title: String, durationMinutes: Int, acuity: Int, budget: Double, clinicianID: String, status: DispenseBatchStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.budget = budget
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DispenseBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DispenseBatchStatus.rejected || next == DispenseBatchStatus.withdrawn
            case .approved:
                return next == DispenseBatchStatus.withdrawn
            case .rejected:
                return next == DispenseBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense batch") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(durationMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> DispenseBatch {
            return DispenseBatch(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                acuity: acuity,
                budget: budget,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense batch in status proposed.
    static func newDispenseBatch(_ code: String, title: String) -> DispenseBatch {
        return DispenseBatch(
            code: code,
            title: title,
            durationMinutes: 0,
            acuity: 0,
            budget: 0.0,
            clinicianID: "",
            status: DispenseBatchStatus.proposed
        )
    }
}
