import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot schedule is in its life cycle.
    enum SlotScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a slot schedule and its current status.
    final class SlotSchedule {
        var code: String
        var title: String
        var summary: String
        var graceDays: Int
        var contactEmail: String
        var limit: Int
        var visitMinutes: Int
        var windowDays: Int
        var capacity: Int
        var cost: Double
        var visible: Bool
        var status: SlotScheduleStatus

        init(code: String, title: String, summary: String, graceDays: Int, contactEmail: String, limit: Int, visitMinutes: Int, windowDays: Int, capacity: Int, cost: Double, visible: Bool, status: SlotScheduleStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.windowDays = windowDays
            self.capacity = capacity
            self.cost = cost
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SlotScheduleStatus.approved || next == SlotScheduleStatus.rejected
            case .approved:
                return next == SlotScheduleStatus.rejected || next == SlotScheduleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SlotScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return (Double(limit) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> SlotSchedule {
            return SlotSchedule(
                code: code,
                title: title,
                summary: summary,
                graceDays: graceDays,
                contactEmail: contactEmail,
                limit: limit,
                visitMinutes: visitMinutes,
                windowDays: windowDays,
                capacity: capacity,
                cost: cost,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot schedule in status proposed.
    static func newSlotSchedule(_ code: String, title: String) -> SlotSchedule {
        return SlotSchedule(
            code: code,
            title: title,
            summary: "",
            graceDays: 0,
            contactEmail: "",
            limit: 0,
            visitMinutes: 0,
            windowDays: 0,
            capacity: 0,
            cost: 0.0,
            visible: false,
            status: SlotScheduleStatus.proposed
        )
    }
}
