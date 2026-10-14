import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global risk score tier is in its life cycle.
    enum GlobalRiskScoreTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global risk score tier, with what the planners need to act on it.
    final class GlobalRiskScoreTier {
        var code: String
        var title: String
        var country: String
        var label: String
        var timezone: String
        var amount: Double
        var status: GlobalRiskScoreTierStatus

        init(code: String, title: String, country: String, label: String, timezone: String, amount: Double, status: GlobalRiskScoreTierStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.label = label
            self.timezone = timezone
            self.amount = amount
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

        func canMoveTo(_ next: GlobalRiskScoreTierStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalRiskScoreTierStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalRiskScoreTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global risk score tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> GlobalRiskScoreTier {
            return GlobalRiskScoreTier(
                code: code,
                title: title,
                country: country,
                label: label,
                timezone: timezone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global risk score tier in status requested.
    static func newGlobalRiskScoreTier(_ code: String, title: String) -> GlobalRiskScoreTier {
        return GlobalRiskScoreTier(
            code: code,
            title: title,
            country: "",
            label: "",
            timezone: "",
            amount: 0.0,
            status: GlobalRiskScoreTierStatus.requested
        )
    }
}
