import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted dispense assignment is in its life cycle.
    enum WeightedDispenseAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a weighted dispense assignment and its current status.
    final class WeightedDispenseAssignment {
        var code: String
        var label: String
        var visitMinutes: Int
        var createdAt: Int
        var bed: String
        var retries: Int
        var expiresAt: Int
        var budget: Double
        var amount: Double
        var status: WeightedDispenseAssignmentStatus

        init(code: String, label: String, visitMinutes: Int, createdAt: Int, bed: String, retries: Int, expiresAt: Int, budget: Double, amount: Double, status: WeightedDispenseAssignmentStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.bed = bed
            self.retries = retries
            self.expiresAt = expiresAt
            self.budget = budget
            self.amount = amount
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

        func canMoveTo(_ next: WeightedDispenseAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedDispenseAssignmentStatus.scheduled || next == WeightedDispenseAssignmentStatus.completed
            case .scheduled:
                return next == WeightedDispenseAssignmentStatus.inProgress || next == WeightedDispenseAssignmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WeightedDispenseAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedDispenseAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted dispense assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("weighted dispense assignment") \(code)"
        }

        func projectedVolume() -> Double {
            return ((amount - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDispenseAssignment {
            return WeightedDispenseAssignment(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                bed: bed,
                retries: retries,
                expiresAt: expiresAt,
                budget: budget,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted dispense assignment in status planned.
    static func newWeightedDispenseAssignment(_ code: String, label: String) -> WeightedDispenseAssignment {
        return WeightedDispenseAssignment(
            code: code,
            label: label,
            visitMinutes: 0,
            createdAt: 0,
            bed: "",
            retries: 0,
            expiresAt: 0,
            budget: 0.0,
            amount: 0.0,
            status: WeightedDispenseAssignmentStatus.planned
        )
    }
}
