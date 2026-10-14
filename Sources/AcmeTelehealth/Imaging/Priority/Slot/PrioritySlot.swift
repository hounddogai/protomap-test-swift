import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority slot is in its life cycle.
    enum PrioritySlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One priority slot, with what the planners need to act on it.
    final class PrioritySlot {
        var code: String
        var title: String
        var bed: String
        var amount: Double
        var region: String
        var status: PrioritySlotStatus

        init(code: String, title: String, bed: String, amount: Double, region: String, status: PrioritySlotStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.amount = amount
            self.region = region
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

        func canMoveTo(_ next: PrioritySlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrioritySlotStatus.reopened || next == PrioritySlotStatus.archived
            case .reopened:
                return next == PrioritySlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrioritySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PrioritySlot {
            return PrioritySlot(code: code, title: title, bed: bed, amount: amount, region: region, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a priority slot in status open.
    static func newPrioritySlot(_ code: String, title: String) -> PrioritySlot {
        return PrioritySlot(
            code: code,
            title: title,
            bed: "",
            amount: 0.0,
            region: "",
            status: PrioritySlotStatus.`open`
        )
    }
}
