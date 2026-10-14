import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient discharge plan summary is in its life cycle.
    enum LenientDischargePlanSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient discharge plan summary and its current status.
    final class LenientDischargePlanSummary {
        var code: String
        var label: String
        var attributes: [String: String]
        var bed: String
        var visible: Bool
        var timezone: String
        var threshold: Double
        var rate: Double
        var durationMinutes: Int
        var facility: String
        var status: LenientDischargePlanSummaryStatus

        init(code: String, label: String, attributes: [String: String], bed: String, visible: Bool, timezone: String, threshold: Double, rate: Double, durationMinutes: Int, facility: String, status: LenientDischargePlanSummaryStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.bed = bed
            self.visible = visible
            self.timezone = timezone
            self.threshold = threshold
            self.rate = rate
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientDischargePlanSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientDischargePlanSummaryStatus.revoked || next == LenientDischargePlanSummaryStatus.expired
            case .granted:
                return next == LenientDischargePlanSummaryStatus.revoked || next == LenientDischargePlanSummaryStatus.expired
            case .revoked:
                return next == LenientDischargePlanSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDischargePlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient discharge plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) + rate) * 100).rounded() / 100
        }

        func copyValue() -> LenientDischargePlanSummary {
            return LenientDischargePlanSummary(
                code: code,
                label: label,
                attributes: attributes,
                bed: bed,
                visible: visible,
                timezone: timezone,
                threshold: threshold,
                rate: rate,
                durationMinutes: durationMinutes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient discharge plan summary in status requested.
    static func newLenientDischargePlanSummary(_ code: String, label: String) -> LenientDischargePlanSummary {
        return LenientDischargePlanSummary(
            code: code,
            label: label,
            attributes: [:],
            bed: "",
            visible: false,
            timezone: "",
            threshold: 0.0,
            rate: 0.0,
            durationMinutes: 0,
            facility: "",
            status: LenientDischargePlanSummaryStatus.requested
        )
    }
}
