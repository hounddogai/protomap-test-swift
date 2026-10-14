import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict denial milestone is in its life cycle.
    enum StrictDenialMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict denial milestone as the denial team keeps it.
    final class StrictDenialMilestone {
        var code: String
        var title: String
        var expiresAt: Int
        var ward: String
        var currency: String
        var durationMinutes: Int
        var externalRef: String
        var status: StrictDenialMilestoneStatus

        init(code: String, title: String, expiresAt: Int, ward: String, currency: String, durationMinutes: Int, externalRef: String, status: StrictDenialMilestoneStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.ward = ward
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
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

        func canMoveTo(_ next: StrictDenialMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictDenialMilestoneStatus.rejected || next == StrictDenialMilestoneStatus.withdrawn
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

        func moveTo(_ next: StrictDenialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict denial milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(expiresAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictDenialMilestone {
            return StrictDenialMilestone(
                code: code,
                title: title,
                expiresAt: expiresAt,
                ward: ward,
                currency: currency,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict denial milestone in status proposed.
    static func newStrictDenialMilestone(_ code: String, title: String) -> StrictDenialMilestone {
        return StrictDenialMilestone(
            code: code,
            title: title,
            expiresAt: 0,
            ward: "",
            currency: "",
            durationMinutes: 0,
            externalRef: "",
            status: StrictDenialMilestoneStatus.proposed
        )
    }
}
