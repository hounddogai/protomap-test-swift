import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched census agreement is in its life cycle.
    enum BatchedCensusAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched census agreement, with what the planners need to act on it.
    final class BatchedCensusAgreement {
        var code: String
        var name: String
        var procedureCode: String
        var facility: String
        var specialty: String
        var pinned: Bool
        var payer: String
        var dosageMg: Double
        var phone: String
        var status: BatchedCensusAgreementStatus

        init(code: String, name: String, procedureCode: String, facility: String, specialty: String, pinned: Bool, payer: String, dosageMg: Double, phone: String, status: BatchedCensusAgreementStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.facility = facility
            self.specialty = specialty
            self.pinned = pinned
            self.payer = payer
            self.dosageMg = dosageMg
            self.phone = phone
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

        func canMoveTo(_ next: BatchedCensusAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedCensusAgreementStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedCensusAgreementStatus.stopped
            case .draining:
                return next == BatchedCensusAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCensusAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched census agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> BatchedCensusAgreement {
            return BatchedCensusAgreement(
                code: code,
                name: name,
                procedureCode: procedureCode,
                facility: facility,
                specialty: specialty,
                pinned: pinned,
                payer: payer,
                dosageMg: dosageMg,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched census agreement in status idle.
    static func newBatchedCensusAgreement(_ code: String, name: String) -> BatchedCensusAgreement {
        return BatchedCensusAgreement(
            code: code,
            name: name,
            procedureCode: "",
            facility: "",
            specialty: "",
            pinned: false,
            payer: "",
            dosageMg: 0.0,
            phone: "",
            status: BatchedCensusAgreementStatus.idle
        )
    }
}
