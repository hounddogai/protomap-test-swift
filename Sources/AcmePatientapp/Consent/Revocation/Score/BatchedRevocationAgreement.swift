import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched revocation agreement is in its life cycle.
    enum BatchedRevocationAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched revocation agreement, with what the planners need to act on it.
    final class BatchedRevocationAgreement {
        var code: String
        var title: String
        var bed: String
        var reviewer: String
        var discount: Double
        var patientRef: String
        var encounterID: String
        var clinicianID: String
        var sequence: Int
        var status: BatchedRevocationAgreementStatus

        init(code: String, title: String, bed: String, reviewer: String, discount: Double, patientRef: String, encounterID: String, clinicianID: String, sequence: Int, status: BatchedRevocationAgreementStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.reviewer = reviewer
            self.discount = discount
            self.patientRef = patientRef
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedRevocationAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedRevocationAgreementStatus.warming || next == BatchedRevocationAgreementStatus.ready
            case .warming:
                return next == BatchedRevocationAgreementStatus.ready
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedRevocationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched revocation agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((discount + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRevocationAgreement {
            return BatchedRevocationAgreement(
                code: code,
                title: title,
                bed: bed,
                reviewer: reviewer,
                discount: discount,
                patientRef: patientRef,
                encounterID: encounterID,
                clinicianID: clinicianID,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched revocation agreement in status idle.
    static func newBatchedRevocationAgreement(_ code: String, title: String) -> BatchedRevocationAgreement {
        return BatchedRevocationAgreement(
            code: code,
            title: title,
            bed: "",
            reviewer: "",
            discount: 0.0,
            patientRef: "",
            encounterID: "",
            clinicianID: "",
            sequence: 0,
            status: BatchedRevocationAgreementStatus.idle
        )
    }
}
