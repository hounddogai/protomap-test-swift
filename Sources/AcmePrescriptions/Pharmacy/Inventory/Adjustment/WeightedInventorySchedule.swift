import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted inventory schedule is in its life cycle.
    enum WeightedInventoryScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted inventory schedule as the inventory team keeps it.
    final class WeightedInventorySchedule {
        var code: String
        var label: String
        var source: String
        var expiresAt: Int
        var batchSize: Int
        var sequence: Int
        var maximum: Double
        var createdAt: Int
        var copay: Double
        var durationMinutes: Int
        var minimum: Double
        var status: WeightedInventoryScheduleStatus

        init(code: String, label: String, source: String, expiresAt: Int, batchSize: Int, sequence: Int, maximum: Double, createdAt: Int, copay: Double, durationMinutes: Int, minimum: Double, status: WeightedInventoryScheduleStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.sequence = sequence
            self.maximum = maximum
            self.createdAt = createdAt
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.minimum = minimum
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

        func canMoveTo(_ next: WeightedInventoryScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedInventoryScheduleStatus.reopened || next == WeightedInventoryScheduleStatus.archived
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

        func moveTo(_ next: WeightedInventoryScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted inventory schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInventorySchedule {
            return WeightedInventorySchedule(
                code: code,
                label: label,
                source: source,
                expiresAt: expiresAt,
                batchSize: batchSize,
                sequence: sequence,
                maximum: maximum,
                createdAt: createdAt,
                copay: copay,
                durationMinutes: durationMinutes,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted inventory schedule in status open.
    static func newWeightedInventorySchedule(_ code: String, label: String) -> WeightedInventorySchedule {
        return WeightedInventorySchedule(
            code: code,
            label: label,
            source: "",
            expiresAt: 0,
            batchSize: 0,
            sequence: 0,
            maximum: 0.0,
            createdAt: 0,
            copay: 0.0,
            durationMinutes: 0,
            minimum: 0.0,
            status: WeightedInventoryScheduleStatus.`open`
        )
    }
}
