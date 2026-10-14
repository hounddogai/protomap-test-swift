import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global rounding claim is in its life cycle.
    enum GlobalRoundingClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global rounding claim. Its code is unique within a tenant.
    final class GlobalRoundingClaim {
        var code: String
        var label: String
        var attempts: Int
        var floorValue: Double
        var ownerID: String
        var ratio: Double
        var weight: Double
        var currency: String
        var status: GlobalRoundingClaimStatus

        init(code: String, label: String, attempts: Int, floorValue: Double, ownerID: String, ratio: Double, weight: Double, currency: String, status: GlobalRoundingClaimStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.ratio = ratio
            self.weight = weight
            self.currency = currency
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

        func canMoveTo(_ next: GlobalRoundingClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalRoundingClaimStatus.scheduled || next == GlobalRoundingClaimStatus.completed
            case .scheduled:
                return next == GlobalRoundingClaimStatus.inProgress || next == GlobalRoundingClaimStatus.completed
            case .inProgress:
                return next == GlobalRoundingClaimStatus.cancelled
            case .completed:
                return next == GlobalRoundingClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalRoundingClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global rounding claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global rounding claim") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((ratio - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRoundingClaim {
            return GlobalRoundingClaim(
                code: code,
                label: label,
                attempts: attempts,
                floorValue: floorValue,
                ownerID: ownerID,
                ratio: ratio,
                weight: weight,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global rounding claim in status planned.
    static func newGlobalRoundingClaim(_ code: String, label: String) -> GlobalRoundingClaim {
        return GlobalRoundingClaim(
            code: code,
            label: label,
            attempts: 0,
            floorValue: 0.0,
            ownerID: "",
            ratio: 0.0,
            weight: 0.0,
            currency: "",
            status: GlobalRoundingClaimStatus.planned
        )
    }
}
