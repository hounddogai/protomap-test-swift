import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution claim is in its life cycle.
    enum LenientSubstitutionClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient substitution claim as the substitution team keeps it.
    final class LenientSubstitutionClaim {
        var code: String
        var name: String
        var endsAt: Int
        var locale: String
        var updatedAt: Int
        var acuity: Int
        var status: LenientSubstitutionClaimStatus

        init(code: String, name: String, endsAt: Int, locale: String, updatedAt: Int, acuity: Int, status: LenientSubstitutionClaimStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.locale = locale
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientSubstitutionClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientSubstitutionClaimStatus.scheduled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LenientSubstitutionClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSubstitutionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient substitution claim") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(acuity) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientSubstitutionClaim {
            return LenientSubstitutionClaim(
                code: code,
                name: name,
                endsAt: endsAt,
                locale: locale,
                updatedAt: updatedAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient substitution claim in status planned.
    static func newLenientSubstitutionClaim(_ code: String, name: String) -> LenientSubstitutionClaim {
        return LenientSubstitutionClaim(
            code: code,
            name: name,
            endsAt: 0,
            locale: "",
            updatedAt: 0,
            acuity: 0,
            status: LenientSubstitutionClaimStatus.planned
        )
    }
}
