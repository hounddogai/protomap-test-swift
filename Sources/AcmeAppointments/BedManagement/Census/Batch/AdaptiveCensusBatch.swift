import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive census batch is in its life cycle.
    enum AdaptiveCensusBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive census batch. Its code is unique within a tenant.
    final class AdaptiveCensusBatch {
        var code: String
        var label: String
        var graceDays: Int
        var procedureCode: String
        var startsAt: Int
        var amount: Double
        var patientRef: String
        var durationMinutes: Int
        var diagnosisCode: String
        var status: AdaptiveCensusBatchStatus

        init(code: String, label: String, graceDays: Int, procedureCode: String, startsAt: Int, amount: Double, patientRef: String, durationMinutes: Int, diagnosisCode: String, status: AdaptiveCensusBatchStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.startsAt = startsAt
            self.amount = amount
            self.patientRef = patientRef
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveCensusBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveCensusBatchStatus.running
            case .queued:
                return next == AdaptiveCensusBatchStatus.done
            case .running:
                return next == AdaptiveCensusBatchStatus.done
            case .done:
                return next == AdaptiveCensusBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCensusBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive census batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive census batch") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(durationMinutes) + amount) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCensusBatch {
            return AdaptiveCensusBatch(
                code: code,
                label: label,
                graceDays: graceDays,
                procedureCode: procedureCode,
                startsAt: startsAt,
                amount: amount,
                patientRef: patientRef,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive census batch in status new.
    static func newAdaptiveCensusBatch(_ code: String, label: String) -> AdaptiveCensusBatch {
        return AdaptiveCensusBatch(
            code: code,
            label: label,
            graceDays: 0,
            procedureCode: "",
            startsAt: 0,
            amount: 0.0,
            patientRef: "",
            durationMinutes: 0,
            diagnosisCode: "",
            status: AdaptiveCensusBatchStatus.new
        )
    }
}
