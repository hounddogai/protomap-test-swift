import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy summary is in its life cycle.
    enum ProxySummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A proxy summary as the proxy team keeps it.
    final class ProxySummary {
        var code: String
        var label: String
        var ratio: Double
        var reviewer: String
        var copay: Double
        var version: Int
        var ceiling: Double
        var acuity: Int
        var rate: Double
        var tags: [String]
        var budget: Double
        var status: ProxySummaryStatus

        init(code: String, label: String, ratio: Double, reviewer: String, copay: Double, version: Int, ceiling: Double, acuity: Int, rate: Double, tags: [String], budget: Double, status: ProxySummaryStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.reviewer = reviewer
            self.copay = copay
            self.version = version
            self.ceiling = ceiling
            self.acuity = acuity
            self.rate = rate
            self.tags = tags
            self.budget = budget
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

        func canMoveTo(_ next: ProxySummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProxySummaryStatus.warming
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ProxySummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("proxy summary") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return (rate * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> ProxySummary {
            return ProxySummary(
                code: code,
                label: label,
                ratio: ratio,
                reviewer: reviewer,
                copay: copay,
                version: version,
                ceiling: ceiling,
                acuity: acuity,
                rate: rate,
                tags: tags,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a proxy summary in status idle.
    static func newProxySummary(_ code: String, label: String) -> ProxySummary {
        return ProxySummary(
            code: code,
            label: label,
            ratio: 0.0,
            reviewer: "",
            copay: 0.0,
            version: 0,
            ceiling: 0.0,
            acuity: 0,
            rate: 0.0,
            tags: [],
            budget: 0.0,
            status: ProxySummaryStatus.idle
        )
    }
}
