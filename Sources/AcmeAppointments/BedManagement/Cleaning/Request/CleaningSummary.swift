import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning summary is in its life cycle.
    enum CleaningSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A cleaning summary. Its code is unique within a tenant.
    final class CleaningSummary {
        var code: String
        var label: String
        var country: String
        var externalRef: String
        var title: String
        var ward: String
        var graceDays: Int
        var cost: Double
        var channel: String
        var status: CleaningSummaryStatus

        init(code: String, label: String, country: String, externalRef: String, title: String, ward: String, graceDays: Int, cost: Double, channel: String, status: CleaningSummaryStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.externalRef = externalRef
            self.title = title
            self.ward = ward
            self.graceDays = graceDays
            self.cost = cost
            self.channel = channel
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

        func canMoveTo(_ next: CleaningSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == CleaningSummaryStatus.published
            case .validated:
                return next == CleaningSummaryStatus.published
            case .published:
                return next == CleaningSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning summary") \(code)"
        }

        func weightedTotal() -> Double {
            return ((cost + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningSummary {
            return CleaningSummary(
                code: code,
                label: label,
                country: country,
                externalRef: externalRef,
                title: title,
                ward: ward,
                graceDays: graceDays,
                cost: cost,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning summary in status created.
    static func newCleaningSummary(_ code: String, label: String) -> CleaningSummary {
        return CleaningSummary(
            code: code,
            label: label,
            country: "",
            externalRef: "",
            title: "",
            ward: "",
            graceDays: 0,
            cost: 0.0,
            channel: "",
            status: CleaningSummaryStatus.created
        )
    }
}
