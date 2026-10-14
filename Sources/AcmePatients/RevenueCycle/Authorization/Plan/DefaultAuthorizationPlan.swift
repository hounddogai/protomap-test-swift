import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default authorization plan is in its life cycle.
    enum DefaultAuthorizationPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default authorization plan and its current status.
    final class DefaultAuthorizationPlan {
        var code: String
        var name: String
        var windowDays: Int
        var floorValue: Double
        var ownerID: String
        var source: String
        var summary: String
        var description: String
        var status: DefaultAuthorizationPlanStatus

        init(code: String, name: String, windowDays: Int, floorValue: Double, ownerID: String, source: String, summary: String, description: String, status: DefaultAuthorizationPlanStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.source = source
            self.summary = summary
            self.description = description
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

        func canMoveTo(_ next: DefaultAuthorizationPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultAuthorizationPlanStatus.approved || next == DefaultAuthorizationPlanStatus.rejected
            case .approved:
                return next == DefaultAuthorizationPlanStatus.withdrawn
            case .rejected:
                return next == DefaultAuthorizationPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAuthorizationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default authorization plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default authorization plan") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(windowDays) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAuthorizationPlan {
            return DefaultAuthorizationPlan(
                code: code,
                name: name,
                windowDays: windowDays,
                floorValue: floorValue,
                ownerID: ownerID,
                source: source,
                summary: summary,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default authorization plan in status proposed.
    static func newDefaultAuthorizationPlan(_ code: String, name: String) -> DefaultAuthorizationPlan {
        return DefaultAuthorizationPlan(
            code: code,
            name: name,
            windowDays: 0,
            floorValue: 0.0,
            ownerID: "",
            source: "",
            summary: "",
            description: "",
            status: DefaultAuthorizationPlanStatus.proposed
        )
    }
}
