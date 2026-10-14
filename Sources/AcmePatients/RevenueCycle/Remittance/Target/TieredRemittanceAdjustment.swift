import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance adjustment is in its life cycle.
    enum TieredRemittanceAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One tiered remittance adjustment, with what the planners need to act on it.
    final class TieredRemittanceAdjustment {
        var code: String
        var name: String
        var pinned: Bool
        var durationMinutes: Int
        var amount: Double
        var visible: Bool
        var startsAt: Int
        var payer: String
        var status: TieredRemittanceAdjustmentStatus

        init(code: String, name: String, pinned: Bool, durationMinutes: Int, amount: Double, visible: Bool, startsAt: Int, payer: String, status: TieredRemittanceAdjustmentStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.visible = visible
            self.startsAt = startsAt
            self.payer = payer
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

        func canMoveTo(_ next: TieredRemittanceAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredRemittanceAdjustmentStatus.approved
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

        func moveTo(_ next: TieredRemittanceAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceAdjustment {
            return TieredRemittanceAdjustment(
                code: code,
                name: name,
                pinned: pinned,
                durationMinutes: durationMinutes,
                amount: amount,
                visible: visible,
                startsAt: startsAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered remittance adjustment in status proposed.
    static func newTieredRemittanceAdjustment(_ code: String, name: String) -> TieredRemittanceAdjustment {
        return TieredRemittanceAdjustment(
            code: code,
            name: name,
            pinned: false,
            durationMinutes: 0,
            amount: 0.0,
            visible: false,
            startsAt: 0,
            payer: "",
            status: TieredRemittanceAdjustmentStatus.proposed
        )
    }
}
