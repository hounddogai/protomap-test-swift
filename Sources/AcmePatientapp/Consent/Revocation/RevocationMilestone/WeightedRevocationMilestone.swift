import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted revocation milestone is in its life cycle.
    enum WeightedRevocationMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted revocation milestone. Its code is unique within a tenant.
    final class WeightedRevocationMilestone {
        var code: String
        var title: String
        var ward: String
        var threshold: Double
        var visible: Bool
        var budget: Double
        var weight: Double
        var phone: String
        var payer: String
        var status: WeightedRevocationMilestoneStatus

        init(code: String, title: String, ward: String, threshold: Double, visible: Bool, budget: Double, weight: Double, phone: String, payer: String, status: WeightedRevocationMilestoneStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.threshold = threshold
            self.visible = visible
            self.budget = budget
            self.weight = weight
            self.phone = phone
            self.payer = payer
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

        func canMoveTo(_ next: WeightedRevocationMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedRevocationMilestoneStatus.revoked || next == WeightedRevocationMilestoneStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedRevocationMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRevocationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted revocation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (budget * threshold * 100).rounded() / 100
        }

        func copyValue() -> WeightedRevocationMilestone {
            return WeightedRevocationMilestone(
                code: code,
                title: title,
                ward: ward,
                threshold: threshold,
                visible: visible,
                budget: budget,
                weight: weight,
                phone: phone,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted revocation milestone in status requested.
    static func newWeightedRevocationMilestone(_ code: String, title: String) -> WeightedRevocationMilestone {
        return WeightedRevocationMilestone(
            code: code,
            title: title,
            ward: "",
            threshold: 0.0,
            visible: false,
            budget: 0.0,
            weight: 0.0,
            phone: "",
            payer: "",
            status: WeightedRevocationMilestoneStatus.requested
        )
    }
}
