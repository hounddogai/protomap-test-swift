import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive worklist notice is in its life cycle.
    enum AdaptiveWorklistNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One adaptive worklist notice, with what the planners need to act on it.
    final class AdaptiveWorklistNotice {
        var code: String
        var title: String
        var reviewer: String
        var priority: Int
        var bed: String
        var region: String
        var status: AdaptiveWorklistNoticeStatus

        init(code: String, title: String, reviewer: String, priority: Int, bed: String, region: String, status: AdaptiveWorklistNoticeStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.priority = priority
            self.bed = bed
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveWorklistNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveWorklistNoticeStatus.published || next == AdaptiveWorklistNoticeStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AdaptiveWorklistNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive worklist notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> AdaptiveWorklistNotice {
            return AdaptiveWorklistNotice(
                code: code,
                title: title,
                reviewer: reviewer,
                priority: priority,
                bed: bed,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive worklist notice in status created.
    static func newAdaptiveWorklistNotice(_ code: String, title: String) -> AdaptiveWorklistNotice {
        return AdaptiveWorklistNotice(
            code: code,
            title: title,
            reviewer: "",
            priority: 0,
            bed: "",
            region: "",
            status: AdaptiveWorklistNoticeStatus.created
        )
    }
}
