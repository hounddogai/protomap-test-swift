import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive rounding template is in its life cycle.
    enum AdaptiveRoundingTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a adaptive rounding template and its current status.
    final class AdaptiveRoundingTemplate {
        var code: String
        var name: String
        var acuity: Int
        var durationMinutes: Int
        var approved: Bool
        var startsAt: Int
        var tags: [String]
        var status: AdaptiveRoundingTemplateStatus

        init(code: String, name: String, acuity: Int, durationMinutes: Int, approved: Bool, startsAt: Int, tags: [String], status: AdaptiveRoundingTemplateStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.startsAt = startsAt
            self.tags = tags
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

        func canMoveTo(_ next: AdaptiveRoundingTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveRoundingTemplateStatus.revoked
            case .granted:
                return next == AdaptiveRoundingTemplateStatus.expired
            case .revoked:
                return next == AdaptiveRoundingTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRoundingTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive rounding template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return (Double(durationMinutes) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRoundingTemplate {
            return AdaptiveRoundingTemplate(
                code: code,
                name: name,
                acuity: acuity,
                durationMinutes: durationMinutes,
                approved: approved,
                startsAt: startsAt,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive rounding template in status requested.
    static func newAdaptiveRoundingTemplate(_ code: String, name: String) -> AdaptiveRoundingTemplate {
        return AdaptiveRoundingTemplate(
            code: code,
            name: name,
            acuity: 0,
            durationMinutes: 0,
            approved: false,
            startsAt: 0,
            tags: [],
            status: AdaptiveRoundingTemplateStatus.requested
        )
    }
}
