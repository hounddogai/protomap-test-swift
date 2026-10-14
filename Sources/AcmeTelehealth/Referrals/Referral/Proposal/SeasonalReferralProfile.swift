import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal referral profile is in its life cycle.
    enum SeasonalReferralProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal referral profile as the referral team keeps it.
    final class SeasonalReferralProfile {
        var code: String
        var label: String
        var ward: String
        var ceiling: Double
        var graceDays: Int
        var allergy: String
        var durationMinutes: Int
        var weight: Double
        var status: SeasonalReferralProfileStatus

        init(code: String, label: String, ward: String, ceiling: Double, graceDays: Int, allergy: String, durationMinutes: Int, weight: Double, status: SeasonalReferralProfileStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.weight = weight
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

        func canMoveTo(_ next: SeasonalReferralProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalReferralProfileStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == SeasonalReferralProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalReferralProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal referral profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return (weight * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReferralProfile {
            return SeasonalReferralProfile(
                code: code,
                label: label,
                ward: ward,
                ceiling: ceiling,
                graceDays: graceDays,
                allergy: allergy,
                durationMinutes: durationMinutes,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal referral profile in status requested.
    static func newSeasonalReferralProfile(_ code: String, label: String) -> SeasonalReferralProfile {
        return SeasonalReferralProfile(
            code: code,
            label: label,
            ward: "",
            ceiling: 0.0,
            graceDays: 0,
            allergy: "",
            durationMinutes: 0,
            weight: 0.0,
            status: SeasonalReferralProfileStatus.requested
        )
    }
}
