import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered cleaning slot is in its life cycle.
    enum TieredCleaningSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered cleaning slot, with what the planners need to act on it.
    final class TieredCleaningSlot {
        var code: String
        var title: String
        var category: String
        var channel: String
        var unit: String
        var attempts: Int
        var ratio: Double
        var reviewer: String
        var retries: Int
        var status: TieredCleaningSlotStatus

        init(code: String, title: String, category: String, channel: String, unit: String, attempts: Int, ratio: Double, reviewer: String, retries: Int, status: TieredCleaningSlotStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.channel = channel
            self.unit = unit
            self.attempts = attempts
            self.ratio = ratio
            self.reviewer = reviewer
            self.retries = retries
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

        func canMoveTo(_ next: TieredCleaningSlotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredCleaningSlotStatus.resolved || next == TieredCleaningSlotStatus.reopened
            case .inReview:
                return next == TieredCleaningSlotStatus.resolved || next == TieredCleaningSlotStatus.archived
            case .resolved:
                return next == TieredCleaningSlotStatus.reopened || next == TieredCleaningSlotStatus.archived
            case .reopened:
                return next == TieredCleaningSlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCleaningSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered cleaning slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered cleaning slot") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(retries) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCleaningSlot {
            return TieredCleaningSlot(
                code: code,
                title: title,
                category: category,
                channel: channel,
                unit: unit,
                attempts: attempts,
                ratio: ratio,
                reviewer: reviewer,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered cleaning slot in status open.
    static func newTieredCleaningSlot(_ code: String, title: String) -> TieredCleaningSlot {
        return TieredCleaningSlot(
            code: code,
            title: title,
            category: "",
            channel: "",
            unit: "",
            attempts: 0,
            ratio: 0.0,
            reviewer: "",
            retries: 0,
            status: TieredCleaningSlotStatus.`open`
        )
    }
}
