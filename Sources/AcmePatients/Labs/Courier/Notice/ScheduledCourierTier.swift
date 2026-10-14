import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled courier tier is in its life cycle.
    enum ScheduledCourierTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled courier tier, with what the planners need to act on it.
    final class ScheduledCourierTier {
        var code: String
        var title: String
        var cost: Double
        var version: Int
        var attempts: Int
        var revision: Int
        var acuity: Int
        var createdAt: Int
        var region: String
        var status: ScheduledCourierTierStatus

        init(code: String, title: String, cost: Double, version: Int, attempts: Int, revision: Int, acuity: Int, createdAt: Int, region: String, status: ScheduledCourierTierStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.version = version
            self.attempts = attempts
            self.revision = revision
            self.acuity = acuity
            self.createdAt = createdAt
            self.region = region
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

        func canMoveTo(_ next: ScheduledCourierTierStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledCourierTierStatus.expired
            case .granted:
                return next == ScheduledCourierTierStatus.revoked || next == ScheduledCourierTierStatus.expired
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

        func moveTo(_ next: ScheduledCourierTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled courier tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("scheduled courier tier") \(code)"
        }

        func projectedVolume() -> Double {
            return (cost * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCourierTier {
            return ScheduledCourierTier(
                code: code,
                title: title,
                cost: cost,
                version: version,
                attempts: attempts,
                revision: revision,
                acuity: acuity,
                createdAt: createdAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled courier tier in status requested.
    static func newScheduledCourierTier(_ code: String, title: String) -> ScheduledCourierTier {
        return ScheduledCourierTier(
            code: code,
            title: title,
            cost: 0.0,
            version: 0,
            attempts: 0,
            revision: 0,
            acuity: 0,
            createdAt: 0,
            region: "",
            status: ScheduledCourierTierStatus.requested
        )
    }
}
