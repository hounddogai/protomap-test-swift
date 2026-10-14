import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim summary is in its life cycle.
    enum ClaimSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A claim summary as the claim team keeps it.
    final class ClaimSummary {
        var code: String
        var label: String
        var copay: Double
        var endsAt: Int
        var createdAt: Int
        var timezone: String
        var graceDays: Int
        var status: ClaimSummaryStatus

        init(code: String, label: String, copay: Double, endsAt: Int, createdAt: Int, timezone: String, graceDays: Int, status: ClaimSummaryStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.timezone = timezone
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimSummaryStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClaimSummaryStatus.scheduled || next == ClaimSummaryStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ClaimSummaryStatus.completed
            case .completed:
                return next == ClaimSummaryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (Double(endsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ClaimSummary {
            return ClaimSummary(
                code: code,
                label: label,
                copay: copay,
                endsAt: endsAt,
                createdAt: createdAt,
                timezone: timezone,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim summary in status planned.
    static func newClaimSummary(_ code: String, label: String) -> ClaimSummary {
        return ClaimSummary(
            code: code,
            label: label,
            copay: 0.0,
            endsAt: 0,
            createdAt: 0,
            timezone: "",
            graceDays: 0,
            status: ClaimSummaryStatus.planned
        )
    }
}
