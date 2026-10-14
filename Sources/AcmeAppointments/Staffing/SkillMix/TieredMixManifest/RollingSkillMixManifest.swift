import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling skill mix manifest is in its life cycle.
    enum RollingSkillMixManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling skill mix manifest as the skill mix team keeps it.
    final class RollingSkillMixManifest {
        var code: String
        var name: String
        var limit: Int
        var sequence: Int
        var minimum: Double
        var bed: String
        var ward: String
        var status: RollingSkillMixManifestStatus

        init(code: String, name: String, limit: Int, sequence: Int, minimum: Double, bed: String, ward: String, status: RollingSkillMixManifestStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.sequence = sequence
            self.minimum = minimum
            self.bed = bed
            self.ward = ward
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

        func canMoveTo(_ next: RollingSkillMixManifestStatus) -> Bool {
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
                return next == RollingSkillMixManifestStatus.revoked || next == RollingSkillMixManifestStatus.expired
            case .revoked:
                return next == RollingSkillMixManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling skill mix manifest") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSkillMixManifest {
            return RollingSkillMixManifest(
                code: code,
                name: name,
                limit: limit,
                sequence: sequence,
                minimum: minimum,
                bed: bed,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling skill mix manifest in status requested.
    static func newRollingSkillMixManifest(_ code: String, name: String) -> RollingSkillMixManifest {
        return RollingSkillMixManifest(
            code: code,
            name: name,
            limit: 0,
            sequence: 0,
            minimum: 0.0,
            bed: "",
            ward: "",
            status: RollingSkillMixManifestStatus.requested
        )
    }
}
