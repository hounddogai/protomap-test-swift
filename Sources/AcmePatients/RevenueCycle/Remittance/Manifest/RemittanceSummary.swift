import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance summary is in its life cycle.
    enum RemittanceSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One remittance summary, with what the planners need to act on it.
    final class RemittanceSummary {
        var code: String
        var label: String
        var timezone: String
        var region: String
        var encounterID: String
        var score: Double
        var status: RemittanceSummaryStatus

        init(code: String, label: String, timezone: String, region: String, encounterID: String, score: Double, status: RemittanceSummaryStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.region = region
            self.encounterID = encounterID
            self.score = score
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

        func canMoveTo(_ next: RemittanceSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RemittanceSummaryStatus.draining || next == RemittanceSummaryStatus.stopped
            case .draining:
                return next == RemittanceSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RemittanceSummary {
            return RemittanceSummary(
                code: code,
                label: label,
                timezone: timezone,
                region: region,
                encounterID: encounterID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a remittance summary in status idle.
    static func newRemittanceSummary(_ code: String, label: String) -> RemittanceSummary {
        return RemittanceSummary(
            code: code,
            label: label,
            timezone: "",
            region: "",
            encounterID: "",
            score: 0.0,
            status: RemittanceSummaryStatus.idle
        )
    }
}
