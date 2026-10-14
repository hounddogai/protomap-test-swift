import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan tier is in its life cycle.
    enum DischargePlanTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a discharge plan tier and its current status.
    final class DischargePlanTier {
        var code: String
        var name: String
        var label: String
        var timezone: String
        var endsAt: Int
        var amount: Double
        var status: DischargePlanTierStatus

        init(code: String, name: String, label: String, timezone: String, endsAt: Int, amount: Double, status: DischargePlanTierStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.timezone = timezone
            self.endsAt = endsAt
            self.amount = amount
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

        func canMoveTo(_ next: DischargePlanTierStatus) -> Bool {
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
                return next == DischargePlanTierStatus.draining
            case .ready:
                return next == DischargePlanTierStatus.draining || next == DischargePlanTierStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DischargePlanTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("discharge plan tier") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(endsAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanTier {
            return DischargePlanTier(
                code: code,
                name: name,
                label: label,
                timezone: timezone,
                endsAt: endsAt,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan tier in status idle.
    static func newDischargePlanTier(_ code: String, name: String) -> DischargePlanTier {
        return DischargePlanTier(
            code: code,
            name: name,
            label: "",
            timezone: "",
            endsAt: 0,
            amount: 0.0,
            status: DischargePlanTierStatus.idle
        )
    }
}
