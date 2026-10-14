import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal credential tier is in its life cycle.
    enum SeasonalCredentialTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal credential tier, with what the planners need to act on it.
    final class SeasonalCredentialTier {
        var code: String
        var name: String
        var discount: Double
        var windowDays: Int
        var approved: Bool
        var status: SeasonalCredentialTierStatus

        init(code: String, name: String, discount: Double, windowDays: Int, approved: Bool, status: SeasonalCredentialTierStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.windowDays = windowDays
            self.approved = approved
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

        func canMoveTo(_ next: SeasonalCredentialTierStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
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

        func moveTo(_ next: SeasonalCredentialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal credential tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal credential tier") \(code)"
        }

        func effectiveLoad() -> Double {
            return (discount * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCredentialTier {
            return SeasonalCredentialTier(
                code: code,
                name: name,
                discount: discount,
                windowDays: windowDays,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal credential tier in status requested.
    static func newSeasonalCredentialTier(_ code: String, name: String) -> SeasonalCredentialTier {
        return SeasonalCredentialTier(
            code: code,
            name: name,
            discount: 0.0,
            windowDays: 0,
            approved: false,
            status: SeasonalCredentialTierStatus.requested
        )
    }
}
