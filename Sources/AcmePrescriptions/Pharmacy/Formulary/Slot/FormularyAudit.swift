import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary audit is in its life cycle.
    enum FormularyAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One formulary audit, with what the planners need to act on it.
    final class FormularyAudit {
        var code: String
        var label: String
        var patientRef: String
        var ratio: Double
        var country: String
        var dosageMg: Double
        var status: FormularyAuditStatus

        init(code: String, label: String, patientRef: String, ratio: Double, country: String, dosageMg: Double, status: FormularyAuditStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.ratio = ratio
            self.country = country
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: FormularyAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == FormularyAuditStatus.granted || next == FormularyAuditStatus.revoked
            case .granted:
                return next == FormularyAuditStatus.revoked
            case .revoked:
                return next == FormularyAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((ratio - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FormularyAudit {
            return FormularyAudit(
                code: code,
                label: label,
                patientRef: patientRef,
                ratio: ratio,
                country: country,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a formulary audit in status requested.
    static func newFormularyAudit(_ code: String, label: String) -> FormularyAudit {
        return FormularyAudit(
            code: code,
            label: label,
            patientRef: "",
            ratio: 0.0,
            country: "",
            dosageMg: 0.0,
            status: FormularyAuditStatus.requested
        )
    }
}
