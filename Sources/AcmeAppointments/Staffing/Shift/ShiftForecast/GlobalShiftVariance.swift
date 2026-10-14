import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift variance is in its life cycle.
    enum GlobalShiftVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global shift variance. Its code is unique within a tenant.
    final class GlobalShiftVariance {
        var code: String
        var title: String
        var margin: Double
        var sequence: Int
        var floorValue: Double
        var encounterID: String
        var limit: Int
        var archived: Bool
        var unit: String
        var discount: Double
        var capacity: Int
        var status: GlobalShiftVarianceStatus

        init(code: String, title: String, margin: Double, sequence: Int, floorValue: Double, encounterID: String, limit: Int, archived: Bool, unit: String, discount: Double, capacity: Int, status: GlobalShiftVarianceStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.sequence = sequence
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.limit = limit
            self.archived = archived
            self.unit = unit
            self.discount = discount
            self.capacity = capacity
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

        func canMoveTo(_ next: GlobalShiftVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalShiftVarianceStatus.completed
            case .completed:
                return next == GlobalShiftVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalShiftVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((margin - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalShiftVariance {
            return GlobalShiftVariance(
                code: code,
                title: title,
                margin: margin,
                sequence: sequence,
                floorValue: floorValue,
                encounterID: encounterID,
                limit: limit,
                archived: archived,
                unit: unit,
                discount: discount,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global shift variance in status planned.
    static func newGlobalShiftVariance(_ code: String, title: String) -> GlobalShiftVariance {
        return GlobalShiftVariance(
            code: code,
            title: title,
            margin: 0.0,
            sequence: 0,
            floorValue: 0.0,
            encounterID: "",
            limit: 0,
            archived: false,
            unit: "",
            discount: 0.0,
            capacity: 0,
            status: GlobalShiftVarianceStatus.planned
        )
    }
}
