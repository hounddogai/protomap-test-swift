import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer policy is in its life cycle.
    enum TransferPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One transfer policy, with what the planners need to act on it.
    final class TransferPolicy {
        var code: String
        var name: String
        var diagnosisCode: String
        var quantity: Int
        var maximum: Double
        var graceDays: Int
        var clinicianID: String
        var bed: String
        var facility: String
        var status: TransferPolicyStatus

        init(code: String, name: String, diagnosisCode: String, quantity: Int, maximum: Double, graceDays: Int, clinicianID: String, bed: String, facility: String, status: TransferPolicyStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.maximum = maximum
            self.graceDays = graceDays
            self.clinicianID = clinicianID
            self.bed = bed
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == TransferPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer policy") \(code)"
        }

        func projectedVolume() -> Double {
            return ((maximum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TransferPolicy {
            return TransferPolicy(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                maximum: maximum,
                graceDays: graceDays,
                clinicianID: clinicianID,
                bed: bed,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a transfer policy in status open.
    static func newTransferPolicy(_ code: String, name: String) -> TransferPolicy {
        return TransferPolicy(
            code: code,
            name: name,
            diagnosisCode: "",
            quantity: 0,
            maximum: 0.0,
            graceDays: 0,
            clinicianID: "",
            bed: "",
            facility: "",
            status: TransferPolicyStatus.`open`
        )
    }
}
