import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending specimen agreement is in its life cycle.
    enum PendingSpecimenAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending specimen agreement and its current status.
    final class PendingSpecimenAgreement {
        var code: String
        var label: String
        var retries: Int
        var floorValue: Double
        var copay: Double
        var maximum: Double
        var bed: String
        var name: String
        var sequence: Int
        var weight: Double
        var patientRef: String
        var status: PendingSpecimenAgreementStatus

        init(code: String, label: String, retries: Int, floorValue: Double, copay: Double, maximum: Double, bed: String, name: String, sequence: Int, weight: Double, patientRef: String, status: PendingSpecimenAgreementStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.floorValue = floorValue
            self.copay = copay
            self.maximum = maximum
            self.bed = bed
            self.name = name
            self.sequence = sequence
            self.weight = weight
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingSpecimenAgreementStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingSpecimenAgreementStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PendingSpecimenAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSpecimenAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending specimen agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - weight) * 100).rounded() / 100
        }

        func copyValue() -> PendingSpecimenAgreement {
            return PendingSpecimenAgreement(
                code: code,
                label: label,
                retries: retries,
                floorValue: floorValue,
                copay: copay,
                maximum: maximum,
                bed: bed,
                name: name,
                sequence: sequence,
                weight: weight,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending specimen agreement in status planned.
    static func newPendingSpecimenAgreement(_ code: String, label: String) -> PendingSpecimenAgreement {
        return PendingSpecimenAgreement(
            code: code,
            label: label,
            retries: 0,
            floorValue: 0.0,
            copay: 0.0,
            maximum: 0.0,
            bed: "",
            name: "",
            sequence: 0,
            weight: 0.0,
            patientRef: "",
            status: PendingSpecimenAgreementStatus.planned
        )
    }
}
