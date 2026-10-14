import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted goal cycle is in its life cycle.
    enum WeightedGoalCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted goal cycle. Its code is unique within a tenant.
    final class WeightedGoalCycle {
        var code: String
        var title: String
        var floorValue: Double
        var allergy: String
        var margin: Double
        var updatedAt: Int
        var expiresAt: Int
        var limit: Int
        var facility: String
        var endsAt: Int
        var country: String
        var status: WeightedGoalCycleStatus

        init(code: String, title: String, floorValue: Double, allergy: String, margin: Double, updatedAt: Int, expiresAt: Int, limit: Int, facility: String, endsAt: Int, country: String, status: WeightedGoalCycleStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.allergy = allergy
            self.margin = margin
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.limit = limit
            self.facility = facility
            self.endsAt = endsAt
            self.country = country
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

        func canMoveTo(_ next: WeightedGoalCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedGoalCycleStatus.resolved || next == WeightedGoalCycleStatus.reopened
            case .inReview:
                return next == WeightedGoalCycleStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == WeightedGoalCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedGoalCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted goal cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted goal cycle") \(code)"
        }

        func weightedExposure() -> Double {
            return (margin * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedGoalCycle {
            return WeightedGoalCycle(
                code: code,
                title: title,
                floorValue: floorValue,
                allergy: allergy,
                margin: margin,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                limit: limit,
                facility: facility,
                endsAt: endsAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted goal cycle in status open.
    static func newWeightedGoalCycle(_ code: String, title: String) -> WeightedGoalCycle {
        return WeightedGoalCycle(
            code: code,
            title: title,
            floorValue: 0.0,
            allergy: "",
            margin: 0.0,
            updatedAt: 0,
            expiresAt: 0,
            limit: 0,
            facility: "",
            endsAt: 0,
            country: "",
            status: WeightedGoalCycleStatus.`open`
        )
    }
}
