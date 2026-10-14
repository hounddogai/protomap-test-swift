import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional credential claim is in its life cycle.
    enum RegionalCredentialClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional credential claim and its current status.
    final class RegionalCredentialClaim {
        var code: String
        var label: String
        var rate: Double
        var procedureCode: String
        var threshold: Double
        var reviewer: String
        var description: String
        var allergy: String
        var phone: String
        var graceDays: Int
        var quantity: Int
        var status: RegionalCredentialClaimStatus

        init(code: String, label: String, rate: Double, procedureCode: String, threshold: Double, reviewer: String, description: String, allergy: String, phone: String, graceDays: Int, quantity: Int, status: RegionalCredentialClaimStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.reviewer = reviewer
            self.description = description
            self.allergy = allergy
            self.phone = phone
            self.graceDays = graceDays
            self.quantity = quantity
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

        func canMoveTo(_ next: RegionalCredentialClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalCredentialClaimStatus.stopped
            case .warming:
                return next == RegionalCredentialClaimStatus.ready
            case .ready:
                return next == RegionalCredentialClaimStatus.draining || next == RegionalCredentialClaimStatus.stopped
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

        func moveTo(_ next: RegionalCredentialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional credential claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (threshold * rate * 100).rounded() / 100
        }

        func copyValue() -> RegionalCredentialClaim {
            return RegionalCredentialClaim(
                code: code,
                label: label,
                rate: rate,
                procedureCode: procedureCode,
                threshold: threshold,
                reviewer: reviewer,
                description: description,
                allergy: allergy,
                phone: phone,
                graceDays: graceDays,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional credential claim in status idle.
    static func newRegionalCredentialClaim(_ code: String, label: String) -> RegionalCredentialClaim {
        return RegionalCredentialClaim(
            code: code,
            label: label,
            rate: 0.0,
            procedureCode: "",
            threshold: 0.0,
            reviewer: "",
            description: "",
            allergy: "",
            phone: "",
            graceDays: 0,
            quantity: 0,
            status: RegionalCredentialClaimStatus.idle
        )
    }
}
