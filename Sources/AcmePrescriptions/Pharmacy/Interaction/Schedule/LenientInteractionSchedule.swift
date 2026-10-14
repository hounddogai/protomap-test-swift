import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient interaction schedule is in its life cycle.
    enum LenientInteractionScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient interaction schedule as the interaction team keeps it.
    final class LenientInteractionSchedule {
        var code: String
        var title: String
        var copay: Double
        var windowDays: Int
        var visitMinutes: Int
        var source: String
        var ownerID: String
        var durationMinutes: Int
        var status: LenientInteractionScheduleStatus

        init(code: String, title: String, copay: Double, windowDays: Int, visitMinutes: Int, source: String, ownerID: String, durationMinutes: Int, status: LenientInteractionScheduleStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.source = source
            self.ownerID = ownerID
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LenientInteractionScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientInteractionScheduleStatus.scheduled
            case .scheduled:
                return next == LenientInteractionScheduleStatus.completed || next == LenientInteractionScheduleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LenientInteractionScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInteractionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient interaction schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return (Double(durationMinutes) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LenientInteractionSchedule {
            return LenientInteractionSchedule(
                code: code,
                title: title,
                copay: copay,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                source: source,
                ownerID: ownerID,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient interaction schedule in status planned.
    static func newLenientInteractionSchedule(_ code: String, title: String) -> LenientInteractionSchedule {
        return LenientInteractionSchedule(
            code: code,
            title: title,
            copay: 0.0,
            windowDays: 0,
            visitMinutes: 0,
            source: "",
            ownerID: "",
            durationMinutes: 0,
            status: LenientInteractionScheduleStatus.planned
        )
    }
}
