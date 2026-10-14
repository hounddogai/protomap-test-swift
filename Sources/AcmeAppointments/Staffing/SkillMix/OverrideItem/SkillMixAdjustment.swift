import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix adjustment is in its life cycle.
    enum SkillMixAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A skill mix adjustment as the skill mix team keeps it.
    final class SkillMixAdjustment {
        var code: String
        var label: String
        var checksum: String
        var visible: Bool
        var ownerID: String
        var currency: String
        var clinicianID: String
        var name: String
        var title: String
        var quantity: Int
        var status: SkillMixAdjustmentStatus

        init(code: String, label: String, checksum: String, visible: Bool, ownerID: String, currency: String, clinicianID: String, name: String, title: String, quantity: Int, status: SkillMixAdjustmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.visible = visible
            self.ownerID = ownerID
            self.currency = currency
            self.clinicianID = clinicianID
            self.name = name
            self.title = title
            self.quantity = quantity
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

        func canMoveTo(_ next: SkillMixAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SkillMixAdjustmentStatus.revoked
            case .revoked:
                return next == SkillMixAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SkillMixAdjustment {
            return SkillMixAdjustment(
                code: code,
                label: label,
                checksum: checksum,
                visible: visible,
                ownerID: ownerID,
                currency: currency,
                clinicianID: clinicianID,
                name: name,
                title: title,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a skill mix adjustment in status requested.
    static func newSkillMixAdjustment(_ code: String, label: String) -> SkillMixAdjustment {
        return SkillMixAdjustment(
            code: code,
            label: label,
            checksum: "",
            visible: false,
            ownerID: "",
            currency: "",
            clinicianID: "",
            name: "",
            title: "",
            quantity: 0,
            status: SkillMixAdjustmentStatus.requested
        )
    }
}
