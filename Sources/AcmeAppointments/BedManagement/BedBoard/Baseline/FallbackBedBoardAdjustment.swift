import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback bed board adjustment is in its life cycle.
    enum FallbackBedBoardAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback bed board adjustment as the bed board team keeps it.
    final class FallbackBedBoardAdjustment {
        var code: String
        var label: String
        var maximum: Double
        var encounterID: String
        var retries: Int
        var archived: Bool
        var batchSize: Int
        var ward: String
        var windowDays: Int
        var status: FallbackBedBoardAdjustmentStatus

        init(code: String, label: String, maximum: Double, encounterID: String, retries: Int, archived: Bool, batchSize: Int, ward: String, windowDays: Int, status: FallbackBedBoardAdjustmentStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.encounterID = encounterID
            self.retries = retries
            self.archived = archived
            self.batchSize = batchSize
            self.ward = ward
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FallbackBedBoardAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackBedBoardAdjustmentStatus.inProgress || next == FallbackBedBoardAdjustmentStatus.completed
            case .scheduled:
                return next == FallbackBedBoardAdjustmentStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackBedBoardAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackBedBoardAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback bed board adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback bed board adjustment") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(batchSize) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> FallbackBedBoardAdjustment {
            return FallbackBedBoardAdjustment(
                code: code,
                label: label,
                maximum: maximum,
                encounterID: encounterID,
                retries: retries,
                archived: archived,
                batchSize: batchSize,
                ward: ward,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback bed board adjustment in status planned.
    static func newFallbackBedBoardAdjustment(_ code: String, label: String) -> FallbackBedBoardAdjustment {
        return FallbackBedBoardAdjustment(
            code: code,
            label: label,
            maximum: 0.0,
            encounterID: "",
            retries: 0,
            archived: false,
            batchSize: 0,
            ward: "",
            windowDays: 0,
            status: FallbackBedBoardAdjustmentStatus.planned
        )
    }
}
