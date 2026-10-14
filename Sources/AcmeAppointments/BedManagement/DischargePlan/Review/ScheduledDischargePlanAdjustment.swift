import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled discharge plan adjustment is in its life cycle.
    enum ScheduledDischargePlanAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled discharge plan adjustment as the discharge plan team keeps it.
    final class ScheduledDischargePlanAdjustment {
        var code: String
        var title: String
        var durationMinutes: Int
        var contactEmail: String
        var quantity: Int
        var diagnosisCode: String
        var discount: Double
        var locale: String
        var status: ScheduledDischargePlanAdjustmentStatus

        init(code: String, title: String, durationMinutes: Int, contactEmail: String, quantity: Int, diagnosisCode: String, discount: Double, locale: String, status: ScheduledDischargePlanAdjustmentStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.locale = locale
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

        func canMoveTo(_ next: ScheduledDischargePlanAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledDischargePlanAdjustmentStatus.validated
            case .validated:
                return next == ScheduledDischargePlanAdjustmentStatus.published || next == ScheduledDischargePlanAdjustmentStatus.retired
            case .published:
                return next == ScheduledDischargePlanAdjustmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledDischargePlanAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled discharge plan adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) - discount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDischargePlanAdjustment {
            return ScheduledDischargePlanAdjustment(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                quantity: quantity,
                diagnosisCode: diagnosisCode,
                discount: discount,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled discharge plan adjustment in status created.
    static func newScheduledDischargePlanAdjustment(_ code: String, title: String) -> ScheduledDischargePlanAdjustment {
        return ScheduledDischargePlanAdjustment(
            code: code,
            title: title,
            durationMinutes: 0,
            contactEmail: "",
            quantity: 0,
            diagnosisCode: "",
            discount: 0.0,
            locale: "",
            status: ScheduledDischargePlanAdjustmentStatus.created
        )
    }
}
