import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff tier is in its life cycle.
    enum HandoffTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a handoff tier and its current status.
    final class HandoffTier {
        var code: String
        var name: String
        var timezone: String
        var dosageMg: Double
        var country: String
        var label: String
        var status: HandoffTierStatus

        init(code: String, name: String, timezone: String, dosageMg: Double, country: String, label: String, status: HandoffTierStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.dosageMg = dosageMg
            self.country = country
            self.label = label
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

        func canMoveTo(_ next: HandoffTierStatus) -> Bool {
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
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: HandoffTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("handoff tier") \(code)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> HandoffTier {
            return HandoffTier(
                code: code,
                name: name,
                timezone: timezone,
                dosageMg: dosageMg,
                country: country,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a handoff tier in status requested.
    static func newHandoffTier(_ code: String, name: String) -> HandoffTier {
        return HandoffTier(
            code: code,
            name: name,
            timezone: "",
            dosageMg: 0.0,
            country: "",
            label: "",
            status: HandoffTierStatus.requested
        )
    }
}
