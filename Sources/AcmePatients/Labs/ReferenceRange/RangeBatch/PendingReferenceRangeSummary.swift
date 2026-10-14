import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range summary is in its life cycle.
    enum PendingReferenceRangeSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending reference range summary as the reference range team keeps it.
    final class PendingReferenceRangeSummary {
        var code: String
        var title: String
        var ceiling: Double
        var ownerID: String
        var unit: String
        var channel: String
        var ward: String
        var patientRef: String
        var windowDays: Int
        var retries: Int
        var status: PendingReferenceRangeSummaryStatus

        init(code: String, title: String, ceiling: Double, ownerID: String, unit: String, channel: String, ward: String, patientRef: String, windowDays: Int, retries: Int, status: PendingReferenceRangeSummaryStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.unit = unit
            self.channel = channel
            self.ward = ward
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingReferenceRangeSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PendingReferenceRangeSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReferenceRangeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(retries) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PendingReferenceRangeSummary {
            return PendingReferenceRangeSummary(
                code: code,
                title: title,
                ceiling: ceiling,
                ownerID: ownerID,
                unit: unit,
                channel: channel,
                ward: ward,
                patientRef: patientRef,
                windowDays: windowDays,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending reference range summary in status new.
    static func newPendingReferenceRangeSummary(_ code: String, title: String) -> PendingReferenceRangeSummary {
        return PendingReferenceRangeSummary(
            code: code,
            title: title,
            ceiling: 0.0,
            ownerID: "",
            unit: "",
            channel: "",
            ward: "",
            patientRef: "",
            windowDays: 0,
            retries: 0,
            status: PendingReferenceRangeSummaryStatus.new
        )
    }
}
