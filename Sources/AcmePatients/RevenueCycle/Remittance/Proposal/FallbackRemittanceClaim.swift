import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback remittance claim is in its life cycle.
    enum FallbackRemittanceClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback remittance claim as the remittance team keeps it.
    final class FallbackRemittanceClaim {
        var code: String
        var label: String
        var procedureCode: String
        var phone: String
        var contactEmail: String
        var attempts: Int
        var status: FallbackRemittanceClaimStatus

        init(code: String, label: String, procedureCode: String, phone: String, contactEmail: String, attempts: Int, status: FallbackRemittanceClaimStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.phone = phone
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRemittanceClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackRemittanceClaimStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FallbackRemittanceClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback remittance claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> FallbackRemittanceClaim {
            return FallbackRemittanceClaim(
                code: code,
                label: label,
                procedureCode: procedureCode,
                phone: phone,
                contactEmail: contactEmail,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback remittance claim in status draft.
    static func newFallbackRemittanceClaim(_ code: String, label: String) -> FallbackRemittanceClaim {
        return FallbackRemittanceClaim(
            code: code,
            label: label,
            procedureCode: "",
            phone: "",
            contactEmail: "",
            attempts: 0,
            status: FallbackRemittanceClaimStatus.draft
        )
    }
}
