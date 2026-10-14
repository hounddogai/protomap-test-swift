import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility segment is in its life cycle.
    enum EligibilitySegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One eligibility segment, with what the planners need to act on it.
    final class EligibilitySegment {
        var code: String
        var title: String
        var copay: Double
        var timezone: String
        var expiresAt: Int
        var name: String
        var active: Bool
        var createdAt: Int
        var retries: Int
        var durationMinutes: Int
        var status: EligibilitySegmentStatus

        init(code: String, title: String, copay: Double, timezone: String, expiresAt: Int, name: String, active: Bool, createdAt: Int, retries: Int, durationMinutes: Int, status: EligibilitySegmentStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.name = name
            self.active = active
            self.createdAt = createdAt
            self.retries = retries
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: EligibilitySegmentStatus) -> Bool {
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
                return next == EligibilitySegmentStatus.revoked
            case .revoked:
                return next == EligibilitySegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilitySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return (copay * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> EligibilitySegment {
            return EligibilitySegment(
                code: code,
                title: title,
                copay: copay,
                timezone: timezone,
                expiresAt: expiresAt,
                name: name,
                active: active,
                createdAt: createdAt,
                retries: retries,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility segment in status requested.
    static func newEligibilitySegment(_ code: String, title: String) -> EligibilitySegment {
        return EligibilitySegment(
            code: code,
            title: title,
            copay: 0.0,
            timezone: "",
            expiresAt: 0,
            name: "",
            active: false,
            createdAt: 0,
            retries: 0,
            durationMinutes: 0,
            status: EligibilitySegmentStatus.requested
        )
    }
}
