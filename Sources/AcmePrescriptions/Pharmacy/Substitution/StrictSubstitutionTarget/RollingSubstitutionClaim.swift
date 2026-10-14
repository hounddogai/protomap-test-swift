import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling substitution claim is in its life cycle.
    enum RollingSubstitutionClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One rolling substitution claim, with what the planners need to act on it.
    final class RollingSubstitutionClaim {
        var code: String
        var title: String
        var acuity: Int
        var startsAt: Int
        var diagnosisCode: String
        var copay: Double
        var status: RollingSubstitutionClaimStatus

        init(code: String, title: String, acuity: Int, startsAt: Int, diagnosisCode: String, copay: Double, status: RollingSubstitutionClaimStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.copay = copay
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

        func canMoveTo(_ next: RollingSubstitutionClaimStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingSubstitutionClaimStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: RollingSubstitutionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling substitution claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling substitution claim") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(startsAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSubstitutionClaim {
            return RollingSubstitutionClaim(
                code: code,
                title: title,
                acuity: acuity,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling substitution claim in status requested.
    static func newRollingSubstitutionClaim(_ code: String, title: String) -> RollingSubstitutionClaim {
        return RollingSubstitutionClaim(
            code: code,
            title: title,
            acuity: 0,
            startsAt: 0,
            diagnosisCode: "",
            copay: 0.0,
            status: RollingSubstitutionClaimStatus.requested
        )
    }
}
