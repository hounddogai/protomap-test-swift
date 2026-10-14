import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling bed board slot is in its life cycle.
    enum RollingBedBoardSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling bed board slot, with what the planners need to act on it.
    final class RollingBedBoardSlot {
        var code: String
        var title: String
        var weight: Double
        var visible: Bool
        var threshold: Double
        var contactEmail: String
        var graceDays: Int
        var retries: Int
        var channel: String
        var status: RollingBedBoardSlotStatus

        init(code: String, title: String, weight: Double, visible: Bool, threshold: Double, contactEmail: String, graceDays: Int, retries: Int, channel: String, status: RollingBedBoardSlotStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.visible = visible
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.retries = retries
            self.channel = channel
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

        func canMoveTo(_ next: RollingBedBoardSlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingBedBoardSlotStatus.resolved
            case .resolved:
                return next == RollingBedBoardSlotStatus.reopened
            case .reopened:
                return next == RollingBedBoardSlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingBedBoardSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling bed board slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((weight - threshold) * 100).rounded() / 100
        }

        func copyValue() -> RollingBedBoardSlot {
            return RollingBedBoardSlot(
                code: code,
                title: title,
                weight: weight,
                visible: visible,
                threshold: threshold,
                contactEmail: contactEmail,
                graceDays: graceDays,
                retries: retries,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling bed board slot in status open.
    static func newRollingBedBoardSlot(_ code: String, title: String) -> RollingBedBoardSlot {
        return RollingBedBoardSlot(
            code: code,
            title: title,
            weight: 0.0,
            visible: false,
            threshold: 0.0,
            contactEmail: "",
            graceDays: 0,
            retries: 0,
            channel: "",
            status: RollingBedBoardSlotStatus.`open`
        )
    }
}
