import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier summary is in its life cycle.
    enum CourierSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One courier summary, with what the planners need to act on it.
    final class CourierSummary {
        var code: String
        var name: String
        var summary: String
        var pinned: Bool
        var copay: Double
        var threshold: Double
        var timezone: String
        var version: Int
        var status: CourierSummaryStatus

        init(code: String, name: String, summary: String, pinned: Bool, copay: Double, threshold: Double, timezone: String, version: Int, status: CourierSummaryStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.pinned = pinned
            self.copay = copay
            self.threshold = threshold
            self.timezone = timezone
            self.version = version
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

        func canMoveTo(_ next: CourierSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == CourierSummaryStatus.validated
            case .validated:
                return next == CourierSummaryStatus.published
            case .published:
                return next == CourierSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((copay + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CourierSummary {
            return CourierSummary(
                code: code,
                name: name,
                summary: summary,
                pinned: pinned,
                copay: copay,
                threshold: threshold,
                timezone: timezone,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier summary in status created.
    static func newCourierSummary(_ code: String, name: String) -> CourierSummary {
        return CourierSummary(
            code: code,
            name: name,
            summary: "",
            pinned: false,
            copay: 0.0,
            threshold: 0.0,
            timezone: "",
            version: 0,
            status: CourierSummaryStatus.created
        )
    }
}
