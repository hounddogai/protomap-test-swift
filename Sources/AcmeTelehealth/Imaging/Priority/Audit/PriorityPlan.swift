import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority plan is in its life cycle.
    enum PriorityPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A priority plan as the priority team keeps it.
    final class PriorityPlan {
        var code: String
        var name: String
        var cost: Double
        var rate: Double
        var threshold: Double
        var archived: Bool
        var version: Int
        var active: Bool
        var source: String
        var minimum: Double
        var durationMinutes: Int
        var status: PriorityPlanStatus

        init(code: String, name: String, cost: Double, rate: Double, threshold: Double, archived: Bool, version: Int, active: Bool, source: String, minimum: Double, durationMinutes: Int, status: PriorityPlanStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.rate = rate
            self.threshold = threshold
            self.archived = archived
            self.version = version
            self.active = active
            self.source = source
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PriorityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("priority plan") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(durationMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> PriorityPlan {
            return PriorityPlan(
                code: code,
                name: name,
                cost: cost,
                rate: rate,
                threshold: threshold,
                archived: archived,
                version: version,
                active: active,
                source: source,
                minimum: minimum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a priority plan in status created.
    static func newPriorityPlan(_ code: String, name: String) -> PriorityPlan {
        return PriorityPlan(
            code: code,
            name: name,
            cost: 0.0,
            rate: 0.0,
            threshold: 0.0,
            archived: false,
            version: 0,
            active: false,
            source: "",
            minimum: 0.0,
            durationMinutes: 0,
            status: PriorityPlanStatus.created
        )
    }
}
