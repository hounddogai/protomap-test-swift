import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential exception is in its life cycle.
    enum CredentialExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A credential exception as the credential team keeps it.
    final class CredentialException {
        var code: String
        var title: String
        var label: String
        var cost: Double
        var payer: String
        var threshold: Double
        var windowDays: Int
        var copay: Double
        var specialty: String
        var facility: String
        var status: CredentialExceptionStatus

        init(code: String, title: String, label: String, cost: Double, payer: String, threshold: Double, windowDays: Int, copay: Double, specialty: String, facility: String, status: CredentialExceptionStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.cost = cost
            self.payer = payer
            self.threshold = threshold
            self.windowDays = windowDays
            self.copay = copay
            self.specialty = specialty
            self.facility = facility
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

        func canMoveTo(_ next: CredentialExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CredentialExceptionStatus.ready
            case .ready:
                return next == CredentialExceptionStatus.stopped
            case .draining:
                return next == CredentialExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((cost - threshold) * 100).rounded() / 100
        }

        func copyValue() -> CredentialException {
            return CredentialException(
                code: code,
                title: title,
                label: label,
                cost: cost,
                payer: payer,
                threshold: threshold,
                windowDays: windowDays,
                copay: copay,
                specialty: specialty,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential exception in status idle.
    static func newCredentialException(_ code: String, title: String) -> CredentialException {
        return CredentialException(
            code: code,
            title: title,
            label: "",
            cost: 0.0,
            payer: "",
            threshold: 0.0,
            windowDays: 0,
            copay: 0.0,
            specialty: "",
            facility: "",
            status: CredentialExceptionStatus.idle
        )
    }
}
