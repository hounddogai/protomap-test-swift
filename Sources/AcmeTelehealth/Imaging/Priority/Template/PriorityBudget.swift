import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority budget is in its life cycle.
    enum PriorityBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A priority budget as the priority team keeps it.
    final class PriorityBudget {
        var code: String
        var name: String
        var allergy: String
        var dosageMg: Double
        var bed: String
        var archived: Bool
        var attributes: [String: String]
        var cost: Double
        var endsAt: Int
        var status: PriorityBudgetStatus

        init(code: String, name: String, allergy: String, dosageMg: Double, bed: String, archived: Bool, attributes: [String: String], cost: Double, endsAt: Int, status: PriorityBudgetStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.bed = bed
            self.archived = archived
            self.attributes = attributes
            self.cost = cost
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PriorityBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PriorityBudgetStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PriorityBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((Double(endsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> PriorityBudget {
            return PriorityBudget(
                code: code,
                name: name,
                allergy: allergy,
                dosageMg: dosageMg,
                bed: bed,
                archived: archived,
                attributes: attributes,
                cost: cost,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority budget in status planned.
    static func newPriorityBudget(_ code: String, name: String) -> PriorityBudget {
        return PriorityBudget(
            code: code,
            name: name,
            allergy: "",
            dosageMg: 0.0,
            bed: "",
            archived: false,
            attributes: [:],
            cost: 0.0,
            endsAt: 0,
            status: PriorityBudgetStatus.planned
        )
    }
}
