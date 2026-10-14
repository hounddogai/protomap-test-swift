import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction schedule is in its life cycle.
    enum InteractionScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One interaction schedule, with what the planners need to act on it.
    final class InteractionSchedule {
        var code: String
        var title: String
        var limit: Int
        var checksum: String
        var contactEmail: String
        var rate: Double
        var status: InteractionScheduleStatus

        init(code: String, title: String, limit: Int, checksum: String, contactEmail: String, rate: Double, status: InteractionScheduleStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.rate = rate
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

        func canMoveTo(_ next: InteractionScheduleStatus) -> Bool {
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
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: InteractionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return ((rate - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionSchedule {
            return InteractionSchedule(
                code: code,
                title: title,
                limit: limit,
                checksum: checksum,
                contactEmail: contactEmail,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction schedule in status planned.
    static func newInteractionSchedule(_ code: String, title: String) -> InteractionSchedule {
        return InteractionSchedule(
            code: code,
            title: title,
            limit: 0,
            checksum: "",
            contactEmail: "",
            rate: 0.0,
            status: InteractionScheduleStatus.planned
        )
    }
}
