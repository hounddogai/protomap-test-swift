import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched revocation digest is in its life cycle.
    enum BatchedRevocationDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched revocation digest and its current status.
    final class BatchedRevocationDigest {
        var code: String
        var label: String
        var expiresAt: Int
        var specialty: String
        var amount: Double
        var updatedAt: Int
        var dosageMg: Double
        var procedureCode: String
        var phone: String
        var bed: String
        var status: BatchedRevocationDigestStatus

        init(code: String, label: String, expiresAt: Int, specialty: String, amount: Double, updatedAt: Int, dosageMg: Double, procedureCode: String, phone: String, bed: String, status: BatchedRevocationDigestStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.specialty = specialty
            self.amount = amount
            self.updatedAt = updatedAt
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.phone = phone
            self.bed = bed
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

        func canMoveTo(_ next: BatchedRevocationDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedRevocationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched revocation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return (Double(expiresAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> BatchedRevocationDigest {
            return BatchedRevocationDigest(
                code: code,
                label: label,
                expiresAt: expiresAt,
                specialty: specialty,
                amount: amount,
                updatedAt: updatedAt,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                phone: phone,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched revocation digest in status planned.
    static func newBatchedRevocationDigest(_ code: String, label: String) -> BatchedRevocationDigest {
        return BatchedRevocationDigest(
            code: code,
            label: label,
            expiresAt: 0,
            specialty: "",
            amount: 0.0,
            updatedAt: 0,
            dosageMg: 0.0,
            procedureCode: "",
            phone: "",
            bed: "",
            status: BatchedRevocationDigestStatus.planned
        )
    }
}
