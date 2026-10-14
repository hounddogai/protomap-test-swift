import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance exception is in its life cycle.
    enum TieredRemittanceExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered remittance exception as the remittance team keeps it.
    final class TieredRemittanceException {
        var code: String
        var title: String
        var quantity: Int
        var specialty: String
        var summary: String
        var durationMinutes: Int
        var status: TieredRemittanceExceptionStatus

        init(code: String, title: String, quantity: Int, specialty: String, summary: String, durationMinutes: Int, status: TieredRemittanceExceptionStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.specialty = specialty
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredRemittanceExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredRemittanceExceptionStatus.withdrawn
            case .rejected:
                return next == TieredRemittanceExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return ((Double(durationMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceException {
            return TieredRemittanceException(
                code: code,
                title: title,
                quantity: quantity,
                specialty: specialty,
                summary: summary,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered remittance exception in status proposed.
    static func newTieredRemittanceException(_ code: String, title: String) -> TieredRemittanceException {
        return TieredRemittanceException(
            code: code,
            title: title,
            quantity: 0,
            specialty: "",
            summary: "",
            durationMinutes: 0,
            status: TieredRemittanceExceptionStatus.proposed
        )
    }
}
