import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling skill mix request is in its life cycle.
    enum RollingSkillMixRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling skill mix request, with what the planners need to act on it.
    final class RollingSkillMixRequest {
        var code: String
        var title: String
        var refills: Int
        var active: Bool
        var archived: Bool
        var name: String
        var region: String
        var visible: Bool
        var payer: String
        var status: RollingSkillMixRequestStatus

        init(code: String, title: String, refills: Int, active: Bool, archived: Bool, name: String, region: String, visible: Bool, payer: String, status: RollingSkillMixRequestStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.active = active
            self.archived = archived
            self.name = name
            self.region = region
            self.visible = visible
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingSkillMixRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RollingSkillMixRequestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RollingSkillMixRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling skill mix request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> RollingSkillMixRequest {
            return RollingSkillMixRequest(
                code: code,
                title: title,
                refills: refills,
                active: active,
                archived: archived,
                name: name,
                region: region,
                visible: visible,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling skill mix request in status open.
    static func newRollingSkillMixRequest(_ code: String, title: String) -> RollingSkillMixRequest {
        return RollingSkillMixRequest(
            code: code,
            title: title,
            refills: 0,
            active: false,
            archived: false,
            name: "",
            region: "",
            visible: false,
            payer: "",
            status: RollingSkillMixRequestStatus.`open`
        )
    }
}
