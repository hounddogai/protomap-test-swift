import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered skill mix claim is in its life cycle.
    enum TieredSkillMixClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered skill mix claim. Its code is unique within a tenant.
    final class TieredSkillMixClaim {
        var code: String
        var name: String
        var retries: Int
        var allergy: String
        var weight: Double
        var category: String
        var dosageMg: Double
        var segment: String
        var expiresAt: Int
        var minimum: Double
        var status: TieredSkillMixClaimStatus

        init(code: String, name: String, retries: Int, allergy: String, weight: Double, category: String, dosageMg: Double, segment: String, expiresAt: Int, minimum: Double, status: TieredSkillMixClaimStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.allergy = allergy
            self.weight = weight
            self.category = category
            self.dosageMg = dosageMg
            self.segment = segment
            self.expiresAt = expiresAt
            self.minimum = minimum
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

        func canMoveTo(_ next: TieredSkillMixClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredSkillMixClaimStatus.rejected
            case .approved:
                return next == TieredSkillMixClaimStatus.withdrawn
            case .rejected:
                return next == TieredSkillMixClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSkillMixClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered skill mix claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return (dosageMg * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> TieredSkillMixClaim {
            return TieredSkillMixClaim(
                code: code,
                name: name,
                retries: retries,
                allergy: allergy,
                weight: weight,
                category: category,
                dosageMg: dosageMg,
                segment: segment,
                expiresAt: expiresAt,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered skill mix claim in status proposed.
    static func newTieredSkillMixClaim(_ code: String, name: String) -> TieredSkillMixClaim {
        return TieredSkillMixClaim(
            code: code,
            name: name,
            retries: 0,
            allergy: "",
            weight: 0.0,
            category: "",
            dosageMg: 0.0,
            segment: "",
            expiresAt: 0,
            minimum: 0.0,
            status: TieredSkillMixClaimStatus.proposed
        )
    }
}
