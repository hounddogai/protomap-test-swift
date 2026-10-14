import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual alert metric is in its life cycle.
    enum ManualAlertMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual alert metric as the alert team keeps it.
    final class ManualAlertMetric {
        var code: String
        var label: String
        var procedureCode: String
        var specialty: String
        var name: String
        var maximum: Double
        var currency: String
        var active: Bool
        var phone: String
        var ward: String
        var contactEmail: String
        var status: ManualAlertMetricStatus

        init(code: String, label: String, procedureCode: String, specialty: String, name: String, maximum: Double, currency: String, active: Bool, phone: String, ward: String, contactEmail: String, status: ManualAlertMetricStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.name = name
            self.maximum = maximum
            self.currency = currency
            self.active = active
            self.phone = phone
            self.ward = ward
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualAlertMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ManualAlertMetricStatus.rejected || next == ManualAlertMetricStatus.withdrawn
            case .rejected:
                return next == ManualAlertMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualAlertMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual alert metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual alert metric") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> ManualAlertMetric {
            return ManualAlertMetric(
                code: code,
                label: label,
                procedureCode: procedureCode,
                specialty: specialty,
                name: name,
                maximum: maximum,
                currency: currency,
                active: active,
                phone: phone,
                ward: ward,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual alert metric in status proposed.
    static func newManualAlertMetric(_ code: String, label: String) -> ManualAlertMetric {
        return ManualAlertMetric(
            code: code,
            label: label,
            procedureCode: "",
            specialty: "",
            name: "",
            maximum: 0.0,
            currency: "",
            active: false,
            phone: "",
            ward: "",
            contactEmail: "",
            status: ManualAlertMetricStatus.proposed
        )
    }
}
