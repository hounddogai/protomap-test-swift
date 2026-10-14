import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient closure notice is in its life cycle.
    enum LenientClosureNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient closure notice and its current status.
    final class LenientClosureNotice {
        var code: String
        var title: String
        var procedureCode: String
        var graceDays: Int
        var tags: [String]
        var reviewer: String
        var ownerID: String
        var checksum: String
        var status: LenientClosureNoticeStatus

        init(code: String, title: String, procedureCode: String, graceDays: Int, tags: [String], reviewer: String, ownerID: String, checksum: String, status: LenientClosureNoticeStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.graceDays = graceDays
            self.tags = tags
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.checksum = checksum
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

        func canMoveTo(_ next: LenientClosureNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientClosureNoticeStatus.resolved
            case .resolved:
                return next == LenientClosureNoticeStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientClosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient closure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient closure notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> LenientClosureNotice {
            return LenientClosureNotice(
                code: code,
                title: title,
                procedureCode: procedureCode,
                graceDays: graceDays,
                tags: tags,
                reviewer: reviewer,
                ownerID: ownerID,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient closure notice in status open.
    static func newLenientClosureNotice(_ code: String, title: String) -> LenientClosureNotice {
        return LenientClosureNotice(
            code: code,
            title: title,
            procedureCode: "",
            graceDays: 0,
            tags: [],
            reviewer: "",
            ownerID: "",
            checksum: "",
            status: LenientClosureNoticeStatus.`open`
        )
    }
}
