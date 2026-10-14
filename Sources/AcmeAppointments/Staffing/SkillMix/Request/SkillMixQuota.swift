import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix quota is in its life cycle.
    enum SkillMixQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a skill mix quota and its current status.
    final class SkillMixQuota {
        var code: String
        var label: String
        var active: Bool
        var title: String
        var bed: String
        var payer: String
        var region: String
        var visible: Bool
        var allergy: String
        var quantity: Int
        var category: String
        var status: SkillMixQuotaStatus

        init(code: String, label: String, active: Bool, title: String, bed: String, payer: String, region: String, visible: Bool, allergy: String, quantity: Int, category: String, status: SkillMixQuotaStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.title = title
            self.bed = bed
            self.payer = payer
            self.region = region
            self.visible = visible
            self.allergy = allergy
            self.quantity = quantity
            self.category = category
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

        func canMoveTo(_ next: SkillMixQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == SkillMixQuotaStatus.expired
            case .granted:
                return next == SkillMixQuotaStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: SkillMixQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SkillMixQuota {
            return SkillMixQuota(
                code: code,
                label: label,
                active: active,
                title: title,
                bed: bed,
                payer: payer,
                region: region,
                visible: visible,
                allergy: allergy,
                quantity: quantity,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a skill mix quota in status requested.
    static func newSkillMixQuota(_ code: String, label: String) -> SkillMixQuota {
        return SkillMixQuota(
            code: code,
            label: label,
            active: false,
            title: "",
            bed: "",
            payer: "",
            region: "",
            visible: false,
            allergy: "",
            quantity: 0,
            category: "",
            status: SkillMixQuotaStatus.requested
        )
    }
}
