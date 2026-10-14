import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization slot is in its life cycle.
    enum AuthorizationSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A authorization slot as the authorization team keeps it.
    final class AuthorizationSlot {
        var code: String
        var label: String
        var payer: String
        var attempts: Int
        var refills: Int
        var status: AuthorizationSlotStatus

        init(code: String, label: String, payer: String, attempts: Int, refills: Int, status: AuthorizationSlotStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.attempts = attempts
            self.refills = refills
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

        func canMoveTo(_ next: AuthorizationSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AuthorizationSlotStatus.ready || next == AuthorizationSlotStatus.draining
            case .ready:
                return next == AuthorizationSlotStatus.stopped
            case .draining:
                return next == AuthorizationSlotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("authorization slot") \(code)"
        }

        func netTotal() -> Double {
            return (Double(attempts) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationSlot {
            return AuthorizationSlot(
                code: code,
                label: label,
                payer: payer,
                attempts: attempts,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization slot in status idle.
    static func newAuthorizationSlot(_ code: String, label: String) -> AuthorizationSlot {
        return AuthorizationSlot(
            code: code,
            label: label,
            payer: "",
            attempts: 0,
            refills: 0,
            status: AuthorizationSlotStatus.idle
        )
    }
}
