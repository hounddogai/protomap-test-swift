import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range schedule is in its life cycle.
    enum LenientReferenceRangeScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient reference range schedule, with what the planners need to act on it.
    final class LenientReferenceRangeSchedule {
        var code: String
        var title: String
        var endsAt: Int
        var capacity: Int
        var locale: String
        var visible: Bool
        var limit: Int
        var sequence: Int
        var notes: String
        var startsAt: Int
        var status: LenientReferenceRangeScheduleStatus

        init(code: String, title: String, endsAt: Int, capacity: Int, locale: String, visible: Bool, limit: Int, sequence: Int, notes: String, startsAt: Int, status: LenientReferenceRangeScheduleStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.capacity = capacity
            self.locale = locale
            self.visible = visible
            self.limit = limit
            self.sequence = sequence
            self.notes = notes
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientReferenceRangeScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientReferenceRangeScheduleStatus.failed
            case .queued:
                return next == LenientReferenceRangeScheduleStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientReferenceRangeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient reference range schedule") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(sequence) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeSchedule {
            return LenientReferenceRangeSchedule(
                code: code,
                title: title,
                endsAt: endsAt,
                capacity: capacity,
                locale: locale,
                visible: visible,
                limit: limit,
                sequence: sequence,
                notes: notes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient reference range schedule in status new.
    static func newLenientReferenceRangeSchedule(_ code: String, title: String) -> LenientReferenceRangeSchedule {
        return LenientReferenceRangeSchedule(
            code: code,
            title: title,
            endsAt: 0,
            capacity: 0,
            locale: "",
            visible: false,
            limit: 0,
            sequence: 0,
            notes: "",
            startsAt: 0,
            status: LenientReferenceRangeScheduleStatus.new
        )
    }
}
