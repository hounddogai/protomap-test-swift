import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary review is in its life cycle.
    enum FormularyReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary review. Its code is unique within a tenant.
    final class FormularyReview {
        var code: String
        var label: String
        var amount: Double
        var acuity: Int
        var procedureCode: String
        var attributes: [String: String]
        var timezone: String
        var status: FormularyReviewStatus

        init(code: String, label: String, amount: Double, acuity: Int, procedureCode: String, attributes: [String: String], timezone: String, status: FormularyReviewStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.acuity = acuity
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.timezone = timezone
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

        func canMoveTo(_ next: FormularyReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == FormularyReviewStatus.granted
            case .granted:
                return next == FormularyReviewStatus.revoked || next == FormularyReviewStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func netLoad() -> Double {
            return ((Double(acuity) - amount) * 100).rounded() / 100
        }

        func copyValue() -> FormularyReview {
            return FormularyReview(
                code: code,
                label: label,
                amount: amount,
                acuity: acuity,
                procedureCode: procedureCode,
                attributes: attributes,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary review in status requested.
    static func newFormularyReview(_ code: String, label: String) -> FormularyReview {
        return FormularyReview(
            code: code,
            label: label,
            amount: 0.0,
            acuity: 0,
            procedureCode: "",
            attributes: [:],
            timezone: "",
            status: FormularyReviewStatus.requested
        )
    }
}
