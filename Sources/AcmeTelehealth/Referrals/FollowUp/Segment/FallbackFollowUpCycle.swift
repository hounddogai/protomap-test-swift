import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback follow up cycle is in its life cycle.
    enum FallbackFollowUpCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback follow up cycle. Its code is unique within a tenant.
    final class FallbackFollowUpCycle {
        var code: String
        var name: String
        var cost: Double
        var archived: Bool
        var capacity: Int
        var visitMinutes: Int
        var ceiling: Double
        var discount: Double
        var description: String
        var region: String
        var allergy: String
        var status: FallbackFollowUpCycleStatus

        init(code: String, name: String, cost: Double, archived: Bool, capacity: Int, visitMinutes: Int, ceiling: Double, discount: Double, description: String, region: String, allergy: String, status: FallbackFollowUpCycleStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.archived = archived
            self.capacity = capacity
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.discount = discount
            self.description = description
            self.region = region
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackFollowUpCycleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackFollowUpCycleStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FallbackFollowUpCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback follow up cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return ((cost - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFollowUpCycle {
            return FallbackFollowUpCycle(
                code: code,
                name: name,
                cost: cost,
                archived: archived,
                capacity: capacity,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                discount: discount,
                description: description,
                region: region,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback follow up cycle in status planned.
    static func newFallbackFollowUpCycle(_ code: String, name: String) -> FallbackFollowUpCycle {
        return FallbackFollowUpCycle(
            code: code,
            name: name,
            cost: 0.0,
            archived: false,
            capacity: 0,
            visitMinutes: 0,
            ceiling: 0.0,
            discount: 0.0,
            description: "",
            region: "",
            allergy: "",
            status: FallbackFollowUpCycleStatus.planned
        )
    }
}
