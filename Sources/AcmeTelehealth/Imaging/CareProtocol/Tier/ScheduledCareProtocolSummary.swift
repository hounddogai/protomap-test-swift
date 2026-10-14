import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol summary is in its life cycle.
    enum ScheduledCareProtocolSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled care protocol summary as the care protocol team keeps it.
    final class ScheduledCareProtocolSummary {
        var code: String
        var label: String
        var allergy: String
        var facility: String
        var rate: Double
        var externalRef: String
        var status: ScheduledCareProtocolSummaryStatus

        init(code: String, label: String, allergy: String, facility: String, rate: Double, externalRef: String, status: ScheduledCareProtocolSummaryStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.facility = facility
            self.rate = rate
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ScheduledCareProtocolSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledCareProtocolSummaryStatus.ready || next == ScheduledCareProtocolSummaryStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ScheduledCareProtocolSummaryStatus.draining
            case .draining:
                return next == ScheduledCareProtocolSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> ScheduledCareProtocolSummary {
            return ScheduledCareProtocolSummary(
                code: code,
                label: label,
                allergy: allergy,
                facility: facility,
                rate: rate,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled care protocol summary in status idle.
    static func newScheduledCareProtocolSummary(_ code: String, label: String) -> ScheduledCareProtocolSummary {
        return ScheduledCareProtocolSummary(
            code: code,
            label: label,
            allergy: "",
            facility: "",
            rate: 0.0,
            externalRef: "",
            status: ScheduledCareProtocolSummaryStatus.idle
        )
    }
}
