import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling witness review is in its life cycle.
    enum RollingWitnessReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling witness review as the witness team keeps it.
    final class RollingWitnessReview {
        var code: String
        var name: String
        var durationMinutes: Int
        var active: Bool
        var capacity: Int
        var clinicianID: String
        var status: RollingWitnessReviewStatus

        init(code: String, name: String, durationMinutes: Int, active: Bool, capacity: Int, clinicianID: String, status: RollingWitnessReviewStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.active = active
            self.capacity = capacity
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: RollingWitnessReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RollingWitnessReviewStatus.revoked || next == RollingWitnessReviewStatus.expired
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

        func moveTo(_ next: RollingWitnessReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling witness review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingWitnessReview {
            return RollingWitnessReview(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                active: active,
                capacity: capacity,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling witness review in status requested.
    static func newRollingWitnessReview(_ code: String, name: String) -> RollingWitnessReview {
        return RollingWitnessReview(
            code: code,
            name: name,
            durationMinutes: 0,
            active: false,
            capacity: 0,
            clinicianID: "",
            status: RollingWitnessReviewStatus.requested
        )
    }
}
