import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation quota is in its life cycle.
    enum RevocationQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A revocation quota as the revocation team keeps it.
    final class RevocationQuota {
        var code: String
        var label: String
        var facility: String
        var threshold: Double
        var quantity: Int
        var specialty: String
        var ratio: Double
        var margin: Double
        var minimum: Double
        var amount: Double
        var contactEmail: String
        var status: RevocationQuotaStatus

        init(code: String, label: String, facility: String, threshold: Double, quantity: Int, specialty: String, ratio: Double, margin: Double, minimum: Double, amount: Double, contactEmail: String, status: RevocationQuotaStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.threshold = threshold
            self.quantity = quantity
            self.specialty = specialty
            self.ratio = ratio
            self.margin = margin
            self.minimum = minimum
            self.amount = amount
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RevocationQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == RevocationQuotaStatus.inProgress || next == RevocationQuotaStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RevocationQuotaStatus.completed || next == RevocationQuotaStatus.cancelled
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

        func moveTo(_ next: RevocationQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation quota") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(quantity) * ratio * 100).rounded() / 100
        }

        func copyValue() -> RevocationQuota {
            return RevocationQuota(
                code: code,
                label: label,
                facility: facility,
                threshold: threshold,
                quantity: quantity,
                specialty: specialty,
                ratio: ratio,
                margin: margin,
                minimum: minimum,
                amount: amount,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a revocation quota in status planned.
    static func newRevocationQuota(_ code: String, label: String) -> RevocationQuota {
        return RevocationQuota(
            code: code,
            label: label,
            facility: "",
            threshold: 0.0,
            quantity: 0,
            specialty: "",
            ratio: 0.0,
            margin: 0.0,
            minimum: 0.0,
            amount: 0.0,
            contactEmail: "",
            status: RevocationQuotaStatus.planned
        )
    }
}
