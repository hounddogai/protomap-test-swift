import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime claim is in its life cycle.
    enum OvertimeClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime claim as the overtime team keeps it.
    final class OvertimeClaim {
        var code: String
        var label: String
        var timezone: String
        var startsAt: Int
        var locale: String
        var status: OvertimeClaimStatus

        init(code: String, label: String, timezone: String, startsAt: Int, locale: String, status: OvertimeClaimStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.startsAt = startsAt
            self.locale = locale
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

        func canMoveTo(_ next: OvertimeClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == OvertimeClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("overtime claim") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> OvertimeClaim {
            return OvertimeClaim(
                code: code,
                label: label,
                timezone: timezone,
                startsAt: startsAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a overtime claim in status proposed.
    static func newOvertimeClaim(_ code: String, label: String) -> OvertimeClaim {
        return OvertimeClaim(
            code: code,
            label: label,
            timezone: "",
            startsAt: 0,
            locale: "",
            status: OvertimeClaimStatus.proposed
        )
    }
}
