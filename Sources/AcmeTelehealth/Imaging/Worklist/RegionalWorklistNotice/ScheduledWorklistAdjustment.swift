import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled worklist adjustment is in its life cycle.
    enum ScheduledWorklistAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One scheduled worklist adjustment, with what the planners need to act on it.
    final class ScheduledWorklistAdjustment {
        var code: String
        var label: String
        var specialty: String
        var unit: String
        var copay: Double
        var procedureCode: String
        var batchSize: Int
        var status: ScheduledWorklistAdjustmentStatus

        init(code: String, label: String, specialty: String, unit: String, copay: Double, procedureCode: String, batchSize: Int, status: ScheduledWorklistAdjustmentStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.unit = unit
            self.copay = copay
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledWorklistAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledWorklistAdjustmentStatus.validated || next == ScheduledWorklistAdjustmentStatus.retired
            case .validated:
                return next == ScheduledWorklistAdjustmentStatus.published || next == ScheduledWorklistAdjustmentStatus.retired
            case .published:
                return next == ScheduledWorklistAdjustmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledWorklistAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled worklist adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled worklist adjustment") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((copay - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledWorklistAdjustment {
            return ScheduledWorklistAdjustment(
                code: code,
                label: label,
                specialty: specialty,
                unit: unit,
                copay: copay,
                procedureCode: procedureCode,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled worklist adjustment in status created.
    static func newScheduledWorklistAdjustment(_ code: String, label: String) -> ScheduledWorklistAdjustment {
        return ScheduledWorklistAdjustment(
            code: code,
            label: label,
            specialty: "",
            unit: "",
            copay: 0.0,
            procedureCode: "",
            batchSize: 0,
            status: ScheduledWorklistAdjustmentStatus.created
        )
    }
}
