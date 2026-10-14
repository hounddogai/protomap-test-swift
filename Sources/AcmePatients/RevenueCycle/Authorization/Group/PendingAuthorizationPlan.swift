import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending authorization plan is in its life cycle.
    enum PendingAuthorizationPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending authorization plan and its current status.
    final class PendingAuthorizationPlan {
        var code: String
        var name: String
        var floorValue: Double
        var title: String
        var summary: String
        var budget: Double
        var label: String
        var ratio: Double
        var updatedAt: Int
        var status: PendingAuthorizationPlanStatus

        init(code: String, name: String, floorValue: Double, title: String, summary: String, budget: Double, label: String, ratio: Double, updatedAt: Int, status: PendingAuthorizationPlanStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.title = title
            self.summary = summary
            self.budget = budget
            self.label = label
            self.ratio = ratio
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PendingAuthorizationPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingAuthorizationPlanStatus.granted || next == PendingAuthorizationPlanStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PendingAuthorizationPlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingAuthorizationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending authorization plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((ratio + budget) * 100).rounded() / 100
        }

        func copyValue() -> PendingAuthorizationPlan {
            return PendingAuthorizationPlan(
                code: code,
                name: name,
                floorValue: floorValue,
                title: title,
                summary: summary,
                budget: budget,
                label: label,
                ratio: ratio,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending authorization plan in status requested.
    static func newPendingAuthorizationPlan(_ code: String, name: String) -> PendingAuthorizationPlan {
        return PendingAuthorizationPlan(
            code: code,
            name: name,
            floorValue: 0.0,
            title: "",
            summary: "",
            budget: 0.0,
            label: "",
            ratio: 0.0,
            updatedAt: 0,
            status: PendingAuthorizationPlanStatus.requested
        )
    }
}
