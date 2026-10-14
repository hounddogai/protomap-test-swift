import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility summary is in its life cycle.
    enum EligibilitySummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A eligibility summary as the eligibility team keeps it.
    final class EligibilitySummary {
        var code: String
        var title: String
        var notes: String
        var updatedAt: Int
        var ceiling: Double
        var margin: Double
        var priority: Int
        var checksum: String
        var timezone: String
        var status: EligibilitySummaryStatus

        init(code: String, title: String, notes: String, updatedAt: Int, ceiling: Double, margin: Double, priority: Int, checksum: String, timezone: String, status: EligibilitySummaryStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.margin = margin
            self.priority = priority
            self.checksum = checksum
            self.timezone = timezone
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

        func canMoveTo(_ next: EligibilitySummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == EligibilitySummaryStatus.validated
            case .validated:
                return next == EligibilitySummaryStatus.published
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

        func moveTo(_ next: EligibilitySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((ceiling - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilitySummary {
            return EligibilitySummary(
                code: code,
                title: title,
                notes: notes,
                updatedAt: updatedAt,
                ceiling: ceiling,
                margin: margin,
                priority: priority,
                checksum: checksum,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility summary in status created.
    static func newEligibilitySummary(_ code: String, title: String) -> EligibilitySummary {
        return EligibilitySummary(
            code: code,
            title: title,
            notes: "",
            updatedAt: 0,
            ceiling: 0.0,
            margin: 0.0,
            priority: 0,
            checksum: "",
            timezone: "",
            status: EligibilitySummaryStatus.created
        )
    }
}
