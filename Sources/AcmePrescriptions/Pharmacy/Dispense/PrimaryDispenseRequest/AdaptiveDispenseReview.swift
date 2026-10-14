import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive dispense review is in its life cycle.
    enum AdaptiveDispenseReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive dispense review and its current status.
    final class AdaptiveDispenseReview {
        var code: String
        var label: String
        var encounterID: String
        var payer: String
        var description: String
        var amount: Double
        var status: AdaptiveDispenseReviewStatus

        init(code: String, label: String, encounterID: String, payer: String, description: String, amount: Double, status: AdaptiveDispenseReviewStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.payer = payer
            self.description = description
            self.amount = amount
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

        func canMoveTo(_ next: AdaptiveDispenseReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveDispenseReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveDispenseReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive dispense review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AdaptiveDispenseReview {
            return AdaptiveDispenseReview(
                code: code,
                label: label,
                encounterID: encounterID,
                payer: payer,
                description: description,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive dispense review in status proposed.
    static func newAdaptiveDispenseReview(_ code: String, label: String) -> AdaptiveDispenseReview {
        return AdaptiveDispenseReview(
            code: code,
            label: label,
            encounterID: "",
            payer: "",
            description: "",
            amount: 0.0,
            status: AdaptiveDispenseReviewStatus.proposed
        )
    }
}
