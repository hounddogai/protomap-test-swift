import AcmePlatform
import Foundation

extension Consent {
    /// Where a global consent form template is in its life cycle.
    enum GlobalConsentFormTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global consent form template as the consent form team keeps it.
    final class GlobalConsentFormTemplate {
        var code: String
        var name: String
        var ratio: Double
        var phone: String
        var clinicianID: String
        var amount: Double
        var copay: Double
        var facility: String
        var status: GlobalConsentFormTemplateStatus

        init(code: String, name: String, ratio: Double, phone: String, clinicianID: String, amount: Double, copay: Double, facility: String, status: GlobalConsentFormTemplateStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.phone = phone
            self.clinicianID = clinicianID
            self.amount = amount
            self.copay = copay
            self.facility = facility
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

        func canMoveTo(_ next: GlobalConsentFormTemplateStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalConsentFormTemplateStatus.scheduled || next == GlobalConsentFormTemplateStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalConsentFormTemplateStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalConsentFormTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global consent form template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global consent form template") \(code)"
        }

        func adjustedValue() -> Double {
            return (copay * ratio * 100).rounded() / 100
        }

        func copyValue() -> GlobalConsentFormTemplate {
            return GlobalConsentFormTemplate(
                code: code,
                name: name,
                ratio: ratio,
                phone: phone,
                clinicianID: clinicianID,
                amount: amount,
                copay: copay,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global consent form template in status planned.
    static func newGlobalConsentFormTemplate(_ code: String, name: String) -> GlobalConsentFormTemplate {
        return GlobalConsentFormTemplate(
            code: code,
            name: name,
            ratio: 0.0,
            phone: "",
            clinicianID: "",
            amount: 0.0,
            copay: 0.0,
            facility: "",
            status: GlobalConsentFormTemplateStatus.planned
        )
    }
}
