import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict claim summary is in its life cycle.
    enum StrictClaimSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict claim summary and its current status.
    final class StrictClaimSummary {
        var code: String
        var title: String
        var source: String
        var summary: String
        var expiresAt: Int
        var version: Int
        var updatedAt: Int
        var startsAt: Int
        var label: String
        var status: StrictClaimSummaryStatus

        init(code: String, title: String, source: String, summary: String, expiresAt: Int, version: Int, updatedAt: Int, startsAt: Int, label: String, status: StrictClaimSummaryStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.summary = summary
            self.expiresAt = expiresAt
            self.version = version
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.label = label
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

        func canMoveTo(_ next: StrictClaimSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictClaimSummaryStatus.ready || next == StrictClaimSummaryStatus.stopped
            case .warming:
                return next == StrictClaimSummaryStatus.ready || next == StrictClaimSummaryStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StrictClaimSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictClaimSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict claim summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("strict claim summary") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(startsAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictClaimSummary {
            return StrictClaimSummary(
                code: code,
                title: title,
                source: source,
                summary: summary,
                expiresAt: expiresAt,
                version: version,
                updatedAt: updatedAt,
                startsAt: startsAt,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict claim summary in status idle.
    static func newStrictClaimSummary(_ code: String, title: String) -> StrictClaimSummary {
        return StrictClaimSummary(
            code: code,
            title: title,
            source: "",
            summary: "",
            expiresAt: 0,
            version: 0,
            updatedAt: 0,
            startsAt: 0,
            label: "",
            status: StrictClaimSummaryStatus.idle
        )
    }
}
