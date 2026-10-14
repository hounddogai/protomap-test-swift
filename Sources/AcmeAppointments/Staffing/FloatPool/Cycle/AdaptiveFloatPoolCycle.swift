import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive float pool cycle is in its life cycle.
    enum AdaptiveFloatPoolCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive float pool cycle. Its code is unique within a tenant.
    final class AdaptiveFloatPoolCycle {
        var code: String
        var label: String
        var windowDays: Int
        var name: String
        var cost: Double
        var version: Int
        var budget: Double
        var threshold: Double
        var priority: Int
        var archived: Bool
        var status: AdaptiveFloatPoolCycleStatus

        init(code: String, label: String, windowDays: Int, name: String, cost: Double, version: Int, budget: Double, threshold: Double, priority: Int, archived: Bool, status: AdaptiveFloatPoolCycleStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.name = name
            self.cost = cost
            self.version = version
            self.budget = budget
            self.threshold = threshold
            self.priority = priority
            self.archived = archived
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

        func canMoveTo(_ next: AdaptiveFloatPoolCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveFloatPoolCycleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveFloatPoolCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive float pool cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("adaptive float pool cycle") \(code)"
        }

        func effectiveLoad() -> Double {
            return (cost * budget * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFloatPoolCycle {
            return AdaptiveFloatPoolCycle(
                code: code,
                label: label,
                windowDays: windowDays,
                name: name,
                cost: cost,
                version: version,
                budget: budget,
                threshold: threshold,
                priority: priority,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive float pool cycle in status proposed.
    static func newAdaptiveFloatPoolCycle(_ code: String, label: String) -> AdaptiveFloatPoolCycle {
        return AdaptiveFloatPoolCycle(
            code: code,
            label: label,
            windowDays: 0,
            name: "",
            cost: 0.0,
            version: 0,
            budget: 0.0,
            threshold: 0.0,
            priority: 0,
            archived: false,
            status: AdaptiveFloatPoolCycleStatus.proposed
        )
    }
}
