import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling dispense profile is in its life cycle.
    enum RollingDispenseProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling dispense profile and its current status.
    final class RollingDispenseProfile {
        var code: String
        var title: String
        var amount: Double
        var quantity: Int
        var source: String
        var clinicianID: String
        var status: RollingDispenseProfileStatus

        init(code: String, title: String, amount: Double, quantity: Int, source: String, clinicianID: String, status: RollingDispenseProfileStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.quantity = quantity
            self.source = source
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: RollingDispenseProfileStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingDispenseProfileStatus.approved || next == RollingDispenseProfileStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingDispenseProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling dispense profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((amount + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingDispenseProfile {
            return RollingDispenseProfile(
                code: code,
                title: title,
                amount: amount,
                quantity: quantity,
                source: source,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling dispense profile in status proposed.
    static func newRollingDispenseProfile(_ code: String, title: String) -> RollingDispenseProfile {
        return RollingDispenseProfile(
            code: code,
            title: title,
            amount: 0.0,
            quantity: 0,
            source: "",
            clinicianID: "",
            status: RollingDispenseProfileStatus.proposed
        )
    }
}
