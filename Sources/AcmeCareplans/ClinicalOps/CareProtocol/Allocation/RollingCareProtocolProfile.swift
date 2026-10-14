import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling care protocol profile is in its life cycle.
    enum RollingCareProtocolProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling care protocol profile as the care protocol team keeps it.
    final class RollingCareProtocolProfile {
        var code: String
        var title: String
        var weight: Double
        var capacity: Int
        var ward: String
        var revision: Int
        var timezone: String
        var reviewer: String
        var region: String
        var score: Double
        var status: RollingCareProtocolProfileStatus

        init(code: String, title: String, weight: Double, capacity: Int, ward: String, revision: Int, timezone: String, reviewer: String, region: String, score: Double, status: RollingCareProtocolProfileStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.capacity = capacity
            self.ward = ward
            self.revision = revision
            self.timezone = timezone
            self.reviewer = reviewer
            self.region = region
            self.score = score
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

        func canMoveTo(_ next: RollingCareProtocolProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingCareProtocolProfileStatus.granted || next == RollingCareProtocolProfileStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RollingCareProtocolProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(capacity) - weight) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolProfile {
            return RollingCareProtocolProfile(
                code: code,
                title: title,
                weight: weight,
                capacity: capacity,
                ward: ward,
                revision: revision,
                timezone: timezone,
                reviewer: reviewer,
                region: region,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling care protocol profile in status requested.
    static func newRollingCareProtocolProfile(_ code: String, title: String) -> RollingCareProtocolProfile {
        return RollingCareProtocolProfile(
            code: code,
            title: title,
            weight: 0.0,
            capacity: 0,
            ward: "",
            revision: 0,
            timezone: "",
            reviewer: "",
            region: "",
            score: 0.0,
            status: RollingCareProtocolProfileStatus.requested
        )
    }
}
