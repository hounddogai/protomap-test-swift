import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive overtime agreement is in its life cycle.
    enum AdaptiveOvertimeAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive overtime agreement, with what the planners need to act on it.
    final class AdaptiveOvertimeAgreement {
        var code: String
        var label: String
        var attempts: Int
        var quantity: Int
        var cost: Double
        var contactEmail: String
        var patientRef: String
        var procedureCode: String
        var status: AdaptiveOvertimeAgreementStatus

        init(code: String, label: String, attempts: Int, quantity: Int, cost: Double, contactEmail: String, patientRef: String, procedureCode: String, status: AdaptiveOvertimeAgreementStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.quantity = quantity
            self.cost = cost
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: AdaptiveOvertimeAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveOvertimeAgreementStatus.expired
            case .granted:
                return next == AdaptiveOvertimeAgreementStatus.revoked || next == AdaptiveOvertimeAgreementStatus.expired
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

        func moveTo(_ next: AdaptiveOvertimeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive overtime agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((cost + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOvertimeAgreement {
            return AdaptiveOvertimeAgreement(
                code: code,
                label: label,
                attempts: attempts,
                quantity: quantity,
                cost: cost,
                contactEmail: contactEmail,
                patientRef: patientRef,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive overtime agreement in status requested.
    static func newAdaptiveOvertimeAgreement(_ code: String, label: String) -> AdaptiveOvertimeAgreement {
        return AdaptiveOvertimeAgreement(
            code: code,
            label: label,
            attempts: 0,
            quantity: 0,
            cost: 0.0,
            contactEmail: "",
            patientRef: "",
            procedureCode: "",
            status: AdaptiveOvertimeAgreementStatus.requested
        )
    }
}
