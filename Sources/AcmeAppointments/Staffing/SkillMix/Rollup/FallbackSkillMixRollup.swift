import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback skill mix rollup is in its life cycle.
    enum FallbackSkillMixRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback skill mix rollup, with what the planners need to act on it.
    final class FallbackSkillMixRollup {
        var code: String
        var name: String
        var externalRef: String
        var endsAt: Int
        var copay: Double
        var score: Double
        var ward: String
        var status: FallbackSkillMixRollupStatus

        init(code: String, name: String, externalRef: String, endsAt: Int, copay: Double, score: Double, ward: String, status: FallbackSkillMixRollupStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.copay = copay
            self.score = score
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

        func canMoveTo(_ next: FallbackSkillMixRollupStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackSkillMixRollupStatus.granted || next == FallbackSkillMixRollupStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackSkillMixRollupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackSkillMixRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback skill mix rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSkillMixRollup {
            return FallbackSkillMixRollup(
                code: code,
                name: name,
                externalRef: externalRef,
                endsAt: endsAt,
                copay: copay,
                score: score,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback skill mix rollup in status requested.
    static func newFallbackSkillMixRollup(_ code: String, name: String) -> FallbackSkillMixRollup {
        return FallbackSkillMixRollup(
            code: code,
            name: name,
            externalRef: "",
            endsAt: 0,
            copay: 0.0,
            score: 0.0,
            ward: "",
            status: FallbackSkillMixRollupStatus.requested
        )
    }
}
