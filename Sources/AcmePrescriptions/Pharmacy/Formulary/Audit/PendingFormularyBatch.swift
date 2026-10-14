import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending formulary batch is in its life cycle.
    enum PendingFormularyBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending formulary batch. Its code is unique within a tenant.
    final class PendingFormularyBatch {
        var code: String
        var label: String
        var allergy: String
        var timezone: String
        var ratio: Double
        var threshold: Double
        var notes: String
        var capacity: Int
        var clinicianID: String
        var payer: String
        var status: PendingFormularyBatchStatus

        init(code: String, label: String, allergy: String, timezone: String, ratio: Double, threshold: Double, notes: String, capacity: Int, clinicianID: String, payer: String, status: PendingFormularyBatchStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.timezone = timezone
            self.ratio = ratio
            self.threshold = threshold
            self.notes = notes
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.payer = payer
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

        func canMoveTo(_ next: PendingFormularyBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingFormularyBatchStatus.running || next == PendingFormularyBatchStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingFormularyBatchStatus.done || next == PendingFormularyBatchStatus.failed
            case .done:
                return next == PendingFormularyBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingFormularyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending formulary batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending formulary batch") \(code)"
        }

        func projectedExposure() -> Double {
            return (ratio * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PendingFormularyBatch {
            return PendingFormularyBatch(
                code: code,
                label: label,
                allergy: allergy,
                timezone: timezone,
                ratio: ratio,
                threshold: threshold,
                notes: notes,
                capacity: capacity,
                clinicianID: clinicianID,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending formulary batch in status new.
    static func newPendingFormularyBatch(_ code: String, label: String) -> PendingFormularyBatch {
        return PendingFormularyBatch(
            code: code,
            label: label,
            allergy: "",
            timezone: "",
            ratio: 0.0,
            threshold: 0.0,
            notes: "",
            capacity: 0,
            clinicianID: "",
            payer: "",
            status: PendingFormularyBatchStatus.new
        )
    }
}
