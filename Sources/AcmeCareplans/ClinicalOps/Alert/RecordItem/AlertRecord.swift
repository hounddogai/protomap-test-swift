import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert record is in its life cycle.
    enum AlertRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One alert record, with what the planners need to act on it.
    final class AlertRecord {
        var code: String
        var label: String
        var procedureCode: String
        var threshold: Double
        var active: Bool
        var maximum: Double
        var contactEmail: String
        var status: AlertRecordStatus

        init(code: String, label: String, procedureCode: String, threshold: Double, active: Bool, maximum: Double, contactEmail: String, status: AlertRecordStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.active = active
            self.maximum = maximum
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

        func canMoveTo(_ next: AlertRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AlertRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("alert record") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((maximum - threshold) * 100).rounded() / 100
        }

        func copyValue() -> AlertRecord {
            return AlertRecord(
                code: code,
                label: label,
                procedureCode: procedureCode,
                threshold: threshold,
                active: active,
                maximum: maximum,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert record in status proposed.
    static func newAlertRecord(_ code: String, label: String) -> AlertRecord {
        return AlertRecord(
            code: code,
            label: label,
            procedureCode: "",
            threshold: 0.0,
            active: false,
            maximum: 0.0,
            contactEmail: "",
            status: AlertRecordStatus.proposed
        )
    }
}
