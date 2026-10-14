import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal target is in its life cycle.
    enum GoalTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One goal target, with what the planners need to act on it.
    final class GoalTarget {
        var code: String
        var name: String
        var capacity: Int
        var unit: String
        var attempts: Int
        var category: String
        var source: String
        var durationMinutes: Int
        var dosageMg: Double
        var createdAt: Int
        var status: GoalTargetStatus

        init(code: String, name: String, capacity: Int, unit: String, attempts: Int, category: String, source: String, durationMinutes: Int, dosageMg: Double, createdAt: Int, status: GoalTargetStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.unit = unit
            self.attempts = attempts
            self.category = category
            self.source = source
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
            self.createdAt = createdAt
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

        func canMoveTo(_ next: GoalTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GoalTargetStatus.archived
            case .inReview:
                return next == GoalTargetStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GoalTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return (dosageMg * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> GoalTarget {
            return GoalTarget(
                code: code,
                name: name,
                capacity: capacity,
                unit: unit,
                attempts: attempts,
                category: category,
                source: source,
                durationMinutes: durationMinutes,
                dosageMg: dosageMg,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a goal target in status open.
    static func newGoalTarget(_ code: String, name: String) -> GoalTarget {
        return GoalTarget(
            code: code,
            name: name,
            capacity: 0,
            unit: "",
            attempts: 0,
            category: "",
            source: "",
            durationMinutes: 0,
            dosageMg: 0.0,
            createdAt: 0,
            status: GoalTargetStatus.`open`
        )
    }
}
