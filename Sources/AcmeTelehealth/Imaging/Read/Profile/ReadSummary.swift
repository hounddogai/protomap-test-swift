import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read summary is in its life cycle.
    enum ReadSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A read summary as the read team keeps it.
    final class ReadSummary {
        var code: String
        var title: String
        var ownerID: String
        var summary: String
        var region: String
        var priority: Int
        var status: ReadSummaryStatus

        init(code: String, title: String, ownerID: String, summary: String, region: String, priority: Int, status: ReadSummaryStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.summary = summary
            self.region = region
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReadSummaryStatus.stopped
            case .warming:
                return next == ReadSummaryStatus.ready || next == ReadSummaryStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ReadSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> ReadSummary {
            return ReadSummary(
                code: code,
                title: title,
                ownerID: ownerID,
                summary: summary,
                region: region,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a read summary in status idle.
    static func newReadSummary(_ code: String, title: String) -> ReadSummary {
        return ReadSummary(
            code: code,
            title: title,
            ownerID: "",
            summary: "",
            region: "",
            priority: 0,
            status: ReadSummaryStatus.idle
        )
    }
}
