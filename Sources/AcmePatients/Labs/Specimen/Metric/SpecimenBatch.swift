import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen batch is in its life cycle.
    enum SpecimenBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a specimen batch and its current status.
    final class SpecimenBatch {
        var code: String
        var label: String
        var visitMinutes: Int
        var sequence: Int
        var bed: String
        var source: String
        var currency: String
        var acuity: Int
        var externalRef: String
        var retries: Int
        var active: Bool
        var status: SpecimenBatchStatus

        init(code: String, label: String, visitMinutes: Int, sequence: Int, bed: String, source: String, currency: String, acuity: Int, externalRef: String, retries: Int, active: Bool, status: SpecimenBatchStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.bed = bed
            self.source = source
            self.currency = currency
            self.acuity = acuity
            self.externalRef = externalRef
            self.retries = retries
            self.active = active
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

        func canMoveTo(_ next: SpecimenBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SpecimenBatchStatus.approved || next == SpecimenBatchStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SpecimenBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return (Double(sequence) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenBatch {
            return SpecimenBatch(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                sequence: sequence,
                bed: bed,
                source: source,
                currency: currency,
                acuity: acuity,
                externalRef: externalRef,
                retries: retries,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a specimen batch in status proposed.
    static func newSpecimenBatch(_ code: String, label: String) -> SpecimenBatch {
        return SpecimenBatch(
            code: code,
            label: label,
            visitMinutes: 0,
            sequence: 0,
            bed: "",
            source: "",
            currency: "",
            acuity: 0,
            externalRef: "",
            retries: 0,
            active: false,
            status: SpecimenBatchStatus.proposed
        )
    }
}
