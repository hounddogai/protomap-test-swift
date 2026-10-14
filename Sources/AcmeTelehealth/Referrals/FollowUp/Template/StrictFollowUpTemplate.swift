import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict follow up template is in its life cycle.
    enum StrictFollowUpTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict follow up template as the follow up team keeps it.
    final class StrictFollowUpTemplate {
        var code: String
        var label: String
        var acuity: Int
        var endsAt: Int
        var createdAt: Int
        var tags: [String]
        var discount: Double
        var status: StrictFollowUpTemplateStatus

        init(code: String, label: String, acuity: Int, endsAt: Int, createdAt: Int, tags: [String], discount: Double, status: StrictFollowUpTemplateStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.tags = tags
            self.discount = discount
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

        func canMoveTo(_ next: StrictFollowUpTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictFollowUpTemplateStatus.expired
            case .granted:
                return next == StrictFollowUpTemplateStatus.revoked || next == StrictFollowUpTemplateStatus.expired
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

        func moveTo(_ next: StrictFollowUpTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict follow up template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(createdAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictFollowUpTemplate {
            return StrictFollowUpTemplate(
                code: code,
                label: label,
                acuity: acuity,
                endsAt: endsAt,
                createdAt: createdAt,
                tags: tags,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict follow up template in status requested.
    static func newStrictFollowUpTemplate(_ code: String, label: String) -> StrictFollowUpTemplate {
        return StrictFollowUpTemplate(
            code: code,
            label: label,
            acuity: 0,
            endsAt: 0,
            createdAt: 0,
            tags: [],
            discount: 0.0,
            status: StrictFollowUpTemplateStatus.requested
        )
    }
}
