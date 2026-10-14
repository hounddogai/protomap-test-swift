import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network plan is in its life cycle.
    enum ManualNetworkPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual network plan and its current status.
    final class ManualNetworkPlan {
        var code: String
        var name: String
        var discount: Double
        var title: String
        var limit: Int
        var status: ManualNetworkPlanStatus

        init(code: String, name: String, discount: Double, title: String, limit: Int, status: ManualNetworkPlanStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.title = title
            self.limit = limit
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

        func canMoveTo(_ next: ManualNetworkPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualNetworkPlanStatus.revoked
            case .granted:
                return next == ManualNetworkPlanStatus.revoked
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

        func moveTo(_ next: ManualNetworkPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return ((discount - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkPlan {
            return ManualNetworkPlan(
                code: code,
                name: name,
                discount: discount,
                title: title,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual network plan in status requested.
    static func newManualNetworkPlan(_ code: String, name: String) -> ManualNetworkPlan {
        return ManualNetworkPlan(
            code: code,
            name: name,
            discount: 0.0,
            title: "",
            limit: 0,
            status: ManualNetworkPlanStatus.requested
        )
    }
}
