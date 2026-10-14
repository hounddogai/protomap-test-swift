import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional charge slot is in its life cycle.
    enum RegionalChargeSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional charge slot. Its code is unique within a tenant.
    final class RegionalChargeSlot {
        var code: String
        var label: String
        var expiresAt: Int
        var cost: Double
        var locale: String
        var ceiling: Double
        var status: RegionalChargeSlotStatus

        init(code: String, label: String, expiresAt: Int, cost: Double, locale: String, ceiling: Double, status: RegionalChargeSlotStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.cost = cost
            self.locale = locale
            self.ceiling = ceiling
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

        func canMoveTo(_ next: RegionalChargeSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalChargeSlotStatus.draining || next == RegionalChargeSlotStatus.stopped
            case .draining:
                return next == RegionalChargeSlotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalChargeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional charge slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((ceiling - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalChargeSlot {
            return RegionalChargeSlot(
                code: code,
                label: label,
                expiresAt: expiresAt,
                cost: cost,
                locale: locale,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional charge slot in status idle.
    static func newRegionalChargeSlot(_ code: String, label: String) -> RegionalChargeSlot {
        return RegionalChargeSlot(
            code: code,
            label: label,
            expiresAt: 0,
            cost: 0.0,
            locale: "",
            ceiling: 0.0,
            status: RegionalChargeSlotStatus.idle
        )
    }
}
