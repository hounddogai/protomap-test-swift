import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness summary is in its life cycle.
    enum WitnessSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness summary as the witness team keeps it.
    final class WitnessSummary {
        var code: String
        var label: String
        var summary: String
        var cost: Double
        var visible: Bool
        var status: WitnessSummaryStatus

        init(code: String, label: String, summary: String, cost: Double, visible: Bool, status: WitnessSummaryStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.cost = cost
            self.visible = visible
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

        func canMoveTo(_ next: WitnessSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WitnessSummaryStatus.draining || next == WitnessSummaryStatus.stopped
            case .draining:
                return next == WitnessSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("witness summary") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> WitnessSummary {
            return WitnessSummary(
                code: code,
                label: label,
                summary: summary,
                cost: cost,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness summary in status idle.
    static func newWitnessSummary(_ code: String, label: String) -> WitnessSummary {
        return WitnessSummary(
            code: code,
            label: label,
            summary: "",
            cost: 0.0,
            visible: false,
            status: WitnessSummaryStatus.idle
        )
    }
}
