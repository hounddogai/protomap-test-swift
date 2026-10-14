import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall notice is in its life cycle.
    enum RecallNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One recall notice, with what the planners need to act on it.
    final class RecallNotice {
        var code: String
        var title: String
        var revision: Int
        var procedureCode: String
        var channel: String
        var bed: String
        var status: RecallNoticeStatus

        init(code: String, title: String, revision: Int, procedureCode: String, channel: String, bed: String, status: RecallNoticeStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.procedureCode = procedureCode
            self.channel = channel
            self.bed = bed
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

        func canMoveTo(_ next: RecallNoticeStatus) -> Bool {
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
                return next == RecallNoticeStatus.archived
            case .resolved:
                return next == RecallNoticeStatus.reopened || next == RecallNoticeStatus.archived
            case .reopened:
                return next == RecallNoticeStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("recall notice") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RecallNotice {
            return RecallNotice(
                code: code,
                title: title,
                revision: revision,
                procedureCode: procedureCode,
                channel: channel,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a recall notice in status open.
    static func newRecallNotice(_ code: String, title: String) -> RecallNotice {
        return RecallNotice(
            code: code,
            title: title,
            revision: 0,
            procedureCode: "",
            channel: "",
            bed: "",
            status: RecallNoticeStatus.`open`
        )
    }
}
