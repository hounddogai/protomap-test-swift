import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending outreach plan is in its life cycle.
    enum PendingOutreachPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending outreach plan and its current status.
    final class PendingOutreachPlan {
        var code: String
        var title: String
        var visible: Bool
        var active: Bool
        var phone: String
        var ceiling: Double
        var ratio: Double
        var status: PendingOutreachPlanStatus

        init(code: String, title: String, visible: Bool, active: Bool, phone: String, ceiling: Double, ratio: Double, status: PendingOutreachPlanStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.active = active
            self.phone = phone
            self.ceiling = ceiling
            self.ratio = ratio
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

        func canMoveTo(_ next: PendingOutreachPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingOutreachPlanStatus.revoked
            case .revoked:
                return next == PendingOutreachPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOutreachPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending outreach plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return ((ratio - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PendingOutreachPlan {
            return PendingOutreachPlan(
                code: code,
                title: title,
                visible: visible,
                active: active,
                phone: phone,
                ceiling: ceiling,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending outreach plan in status requested.
    static func newPendingOutreachPlan(_ code: String, title: String) -> PendingOutreachPlan {
        return PendingOutreachPlan(
            code: code,
            title: title,
            visible: false,
            active: false,
            phone: "",
            ceiling: 0.0,
            ratio: 0.0,
            status: PendingOutreachPlanStatus.requested
        )
    }
}
