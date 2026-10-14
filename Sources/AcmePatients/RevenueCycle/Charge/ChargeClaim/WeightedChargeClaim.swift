import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted charge claim is in its life cycle.
    enum WeightedChargeClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted charge claim as the charge team keeps it.
    final class WeightedChargeClaim {
        var code: String
        var name: String
        var contactEmail: String
        var allergy: String
        var endsAt: Int
        var status: WeightedChargeClaimStatus

        init(code: String, name: String, contactEmail: String, allergy: String, endsAt: Int, status: WeightedChargeClaimStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedChargeClaimStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedChargeClaimStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedChargeClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted charge claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted charge claim") \(code)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> WeightedChargeClaim {
            return WeightedChargeClaim(
                code: code,
                name: name,
                contactEmail: contactEmail,
                allergy: allergy,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted charge claim in status requested.
    static func newWeightedChargeClaim(_ code: String, name: String) -> WeightedChargeClaim {
        return WeightedChargeClaim(
            code: code,
            name: name,
            contactEmail: "",
            allergy: "",
            endsAt: 0,
            status: WeightedChargeClaimStatus.requested
        )
    }
}
