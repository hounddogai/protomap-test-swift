import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient discharge plan quota is in its life cycle.
    enum LenientDischargePlanQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a lenient discharge plan quota and its current status.
    final class LenientDischargePlanQuota {
        var code: String
        var label: String
        var title: String
        var floorValue: Double
        var encounterID: String
        var status: LenientDischargePlanQuotaStatus

        init(code: String, label: String, title: String, floorValue: Double, encounterID: String, status: LenientDischargePlanQuotaStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.floorValue = floorValue
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LenientDischargePlanQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientDischargePlanQuotaStatus.published
            case .validated:
                return next == LenientDischargePlanQuotaStatus.published || next == LenientDischargePlanQuotaStatus.retired
            case .published:
                return next == LenientDischargePlanQuotaStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDischargePlanQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient discharge plan quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient discharge plan quota") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> LenientDischargePlanQuota {
            return LenientDischargePlanQuota(
                code: code,
                label: label,
                title: title,
                floorValue: floorValue,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient discharge plan quota in status created.
    static func newLenientDischargePlanQuota(_ code: String, label: String) -> LenientDischargePlanQuota {
        return LenientDischargePlanQuota(
            code: code,
            label: label,
            title: "",
            floorValue: 0.0,
            encounterID: "",
            status: LenientDischargePlanQuotaStatus.created
        )
    }
}
