import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot baseline is in its life cycle.
    enum SlotBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One slot baseline, with what the planners need to act on it.
    final class SlotBaseline {
        var code: String
        var label: String
        var cost: Double
        var capacity: Int
        var maximum: Double
        var ward: String
        var locale: String
        var payer: String
        var approved: Bool
        var status: SlotBaselineStatus

        init(code: String, label: String, cost: Double, capacity: Int, maximum: Double, ward: String, locale: String, payer: String, approved: Bool, status: SlotBaselineStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.capacity = capacity
            self.maximum = maximum
            self.ward = ward
            self.locale = locale
            self.payer = payer
            self.approved = approved
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

        func canMoveTo(_ next: SlotBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SlotBaselineStatus.inProgress || next == SlotBaselineStatus.cancelled
            case .inProgress:
                return next == SlotBaselineStatus.completed || next == SlotBaselineStatus.cancelled
            case .completed:
                return next == SlotBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("slot baseline") \(code)"
        }

        func adjustedVolume() -> Double {
            return (cost * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> SlotBaseline {
            return SlotBaseline(
                code: code,
                label: label,
                cost: cost,
                capacity: capacity,
                maximum: maximum,
                ward: ward,
                locale: locale,
                payer: payer,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a slot baseline in status planned.
    static func newSlotBaseline(_ code: String, label: String) -> SlotBaseline {
        return SlotBaseline(
            code: code,
            label: label,
            cost: 0.0,
            capacity: 0,
            maximum: 0.0,
            ward: "",
            locale: "",
            payer: "",
            approved: false,
            status: SlotBaselineStatus.planned
        )
    }
}
