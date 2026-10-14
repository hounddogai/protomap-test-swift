import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan claim is in its life cycle.
    enum DischargePlanClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A discharge plan claim as the discharge plan team keeps it.
    final class DischargePlanClaim {
        var code: String
        var label: String
        var discount: Double
        var contactEmail: String
        var pinned: Bool
        var status: DischargePlanClaimStatus

        init(code: String, label: String, discount: Double, contactEmail: String, pinned: Bool, status: DischargePlanClaimStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DischargePlanClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> DischargePlanClaim {
            return DischargePlanClaim(
                code: code,
                label: label,
                discount: discount,
                contactEmail: contactEmail,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan claim in status created.
    static func newDischargePlanClaim(_ code: String, label: String) -> DischargePlanClaim {
        return DischargePlanClaim(
            code: code,
            label: label,
            discount: 0.0,
            contactEmail: "",
            pinned: false,
            status: DischargePlanClaimStatus.created
        )
    }
}
