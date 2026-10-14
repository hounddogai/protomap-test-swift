import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census plan is in its life cycle.
    enum ScheduledCensusPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled census plan, with what the planners need to act on it.
    final class ScheduledCensusPlan {
        var code: String
        var title: String
        var procedureCode: String
        var batchSize: Int
        var graceDays: Int
        var specialty: String
        var priority: Int
        var ward: String
        var unit: String
        var dosageMg: Double
        var status: ScheduledCensusPlanStatus

        init(code: String, title: String, procedureCode: String, batchSize: Int, graceDays: Int, specialty: String, priority: Int, ward: String, unit: String, dosageMg: Double, status: ScheduledCensusPlanStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.specialty = specialty
            self.priority = priority
            self.ward = ward
            self.unit = unit
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ScheduledCensusPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledCensusPlanStatus.active || next == ScheduledCensusPlanStatus.closed
            case .active:
                return next == ScheduledCensusPlanStatus.suspended || next == ScheduledCensusPlanStatus.closed
            case .suspended:
                return next == ScheduledCensusPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCensusPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled census plan") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCensusPlan {
            return ScheduledCensusPlan(
                code: code,
                title: title,
                procedureCode: procedureCode,
                batchSize: batchSize,
                graceDays: graceDays,
                specialty: specialty,
                priority: priority,
                ward: ward,
                unit: unit,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled census plan in status draft.
    static func newScheduledCensusPlan(_ code: String, title: String) -> ScheduledCensusPlan {
        return ScheduledCensusPlan(
            code: code,
            title: title,
            procedureCode: "",
            batchSize: 0,
            graceDays: 0,
            specialty: "",
            priority: 0,
            ward: "",
            unit: "",
            dosageMg: 0.0,
            status: ScheduledCensusPlanStatus.draft
        )
    }
}
