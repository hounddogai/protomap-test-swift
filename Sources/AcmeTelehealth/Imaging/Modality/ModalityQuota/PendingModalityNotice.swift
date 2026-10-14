import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending modality notice is in its life cycle.
    enum PendingModalityNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending modality notice, with what the planners need to act on it.
    final class PendingModalityNotice {
        var code: String
        var title: String
        var encounterID: String
        var country: String
        var threshold: Double
        var status: PendingModalityNoticeStatus

        init(code: String, title: String, encounterID: String, country: String, threshold: Double, status: PendingModalityNoticeStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.country = country
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingModalityNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingModalityNoticeStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingModalityNoticeStatus.suspended || next == PendingModalityNoticeStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PendingModalityNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending modality notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> PendingModalityNotice {
            return PendingModalityNotice(
                code: code,
                title: title,
                encounterID: encounterID,
                country: country,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending modality notice in status draft.
    static func newPendingModalityNotice(_ code: String, title: String) -> PendingModalityNotice {
        return PendingModalityNotice(
            code: code,
            title: title,
            encounterID: "",
            country: "",
            threshold: 0.0,
            status: PendingModalityNoticeStatus.draft
        )
    }
}
