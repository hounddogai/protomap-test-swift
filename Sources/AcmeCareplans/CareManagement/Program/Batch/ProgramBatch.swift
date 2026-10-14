import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program batch is in its life cycle.
    enum ProgramBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A program batch. Its code is unique within a tenant.
    final class ProgramBatch {
        var code: String
        var label: String
        var diagnosisCode: String
        var region: String
        var currency: String
        var minimum: Double
        var refills: Int
        var threshold: Double
        var status: ProgramBatchStatus

        init(code: String, label: String, diagnosisCode: String, region: String, currency: String, minimum: Double, refills: Int, threshold: Double, status: ProgramBatchStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.currency = currency
            self.minimum = minimum
            self.refills = refills
            self.threshold = threshold
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

        func canMoveTo(_ next: ProgramBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == ProgramBatchStatus.validated || next == ProgramBatchStatus.retired
            case .validated:
                return next == ProgramBatchStatus.published || next == ProgramBatchStatus.retired
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return ((threshold + minimum) * 100).rounded() / 100
        }

        func copyValue() -> ProgramBatch {
            return ProgramBatch(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                region: region,
                currency: currency,
                minimum: minimum,
                refills: refills,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a program batch in status created.
    static func newProgramBatch(_ code: String, label: String) -> ProgramBatch {
        return ProgramBatch(
            code: code,
            label: label,
            diagnosisCode: "",
            region: "",
            currency: "",
            minimum: 0.0,
            refills: 0,
            threshold: 0.0,
            status: ProgramBatchStatus.created
        )
    }
}
