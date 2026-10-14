import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge exception is in its life cycle.
    enum ChargeExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A charge exception. Its code is unique within a tenant.
    final class ChargeException {
        var code: String
        var title: String
        var pinned: Bool
        var copay: Double
        var cost: Double
        var acuity: Int
        var dosageMg: Double
        var attempts: Int
        var bed: String
        var allergy: String
        var status: ChargeExceptionStatus

        init(code: String, title: String, pinned: Bool, copay: Double, cost: Double, acuity: Int, dosageMg: Double, attempts: Int, bed: String, allergy: String, status: ChargeExceptionStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.copay = copay
            self.cost = cost
            self.acuity = acuity
            self.dosageMg = dosageMg
            self.attempts = attempts
            self.bed = bed
            self.allergy = allergy
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

        func canMoveTo(_ next: ChargeExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ChargeExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("charge exception") \(code)"
        }

        func projectedTotal() -> Double {
            return ((dosageMg - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeException {
            return ChargeException(
                code: code,
                title: title,
                pinned: pinned,
                copay: copay,
                cost: cost,
                acuity: acuity,
                dosageMg: dosageMg,
                attempts: attempts,
                bed: bed,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge exception in status requested.
    static func newChargeException(_ code: String, title: String) -> ChargeException {
        return ChargeException(
            code: code,
            title: title,
            pinned: false,
            copay: 0.0,
            cost: 0.0,
            acuity: 0,
            dosageMg: 0.0,
            attempts: 0,
            bed: "",
            allergy: "",
            status: ChargeExceptionStatus.requested
        )
    }
}
