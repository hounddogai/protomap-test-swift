import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary agreement is in its life cycle.
    enum FormularyAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a formulary agreement and its current status.
    final class FormularyAgreement {
        var code: String
        var title: String
        var encounterID: String
        var diagnosisCode: String
        var attributes: [String: String]
        var graceDays: Int
        var retries: Int
        var margin: Double
        var currency: String
        var amount: Double
        var status: FormularyAgreementStatus

        init(code: String, title: String, encounterID: String, diagnosisCode: String, attributes: [String: String], graceDays: Int, retries: Int, margin: Double, currency: String, amount: Double, status: FormularyAgreementStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.graceDays = graceDays
            self.retries = retries
            self.margin = margin
            self.currency = currency
            self.amount = amount
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

        func canMoveTo(_ next: FormularyAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == FormularyAgreementStatus.ready || next == FormularyAgreementStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FormularyAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func projectedTotal() -> Double {
            return ((margin + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyAgreement {
            return FormularyAgreement(
                code: code,
                title: title,
                encounterID: encounterID,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                graceDays: graceDays,
                retries: retries,
                margin: margin,
                currency: currency,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a formulary agreement in status idle.
    static func newFormularyAgreement(_ code: String, title: String) -> FormularyAgreement {
        return FormularyAgreement(
            code: code,
            title: title,
            encounterID: "",
            diagnosisCode: "",
            attributes: [:],
            graceDays: 0,
            retries: 0,
            margin: 0.0,
            currency: "",
            amount: 0.0,
            status: FormularyAgreementStatus.idle
        )
    }
}
