import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read summary is in its life cycle.
    enum LenientReadSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient read summary as the read team keeps it.
    final class LenientReadSummary {
        var code: String
        var label: String
        var description: String
        var attempts: Int
        var windowDays: Int
        var weight: Double
        var tags: [String]
        var status: LenientReadSummaryStatus

        init(code: String, label: String, description: String, attempts: Int, windowDays: Int, weight: Double, tags: [String], status: LenientReadSummaryStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.attempts = attempts
            self.windowDays = windowDays
            self.weight = weight
            self.tags = tags
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

        func canMoveTo(_ next: LenientReadSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientReadSummaryStatus.draining || next == LenientReadSummaryStatus.stopped
            case .draining:
                return next == LenientReadSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReadSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient read summary") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((Double(windowDays) + weight) * 100).rounded() / 100
        }

        func copyValue() -> LenientReadSummary {
            return LenientReadSummary(
                code: code,
                label: label,
                description: description,
                attempts: attempts,
                windowDays: windowDays,
                weight: weight,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient read summary in status idle.
    static func newLenientReadSummary(_ code: String, label: String) -> LenientReadSummary {
        return LenientReadSummary(
            code: code,
            label: label,
            description: "",
            attempts: 0,
            windowDays: 0,
            weight: 0.0,
            tags: [],
            status: LenientReadSummaryStatus.idle
        )
    }
}
