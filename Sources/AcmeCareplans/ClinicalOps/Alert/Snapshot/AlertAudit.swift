import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert audit is in its life cycle.
    enum AlertAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A alert audit as the alert team keeps it.
    final class AlertAudit {
        var code: String
        var label: String
        var dosageMg: Double
        var procedureCode: String
        var timezone: String
        var sequence: Int
        var country: String
        var status: AlertAuditStatus

        init(code: String, label: String, dosageMg: Double, procedureCode: String, timezone: String, sequence: Int, country: String, status: AlertAuditStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.sequence = sequence
            self.country = country
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

        func canMoveTo(_ next: AlertAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertAuditStatus.revoked
            case .granted:
                return next == AlertAuditStatus.expired
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

        func moveTo(_ next: AlertAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> AlertAudit {
            return AlertAudit(
                code: code,
                label: label,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                timezone: timezone,
                sequence: sequence,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a alert audit in status requested.
    static func newAlertAudit(_ code: String, label: String) -> AlertAudit {
        return AlertAudit(
            code: code,
            label: label,
            dosageMg: 0.0,
            procedureCode: "",
            timezone: "",
            sequence: 0,
            country: "",
            status: AlertAuditStatus.requested
        )
    }
}
