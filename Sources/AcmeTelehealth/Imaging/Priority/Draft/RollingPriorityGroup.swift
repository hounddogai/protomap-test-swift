import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority group is in its life cycle.
    enum RollingPriorityGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One rolling priority group, with what the planners need to act on it.
    final class RollingPriorityGroup {
        var code: String
        var title: String
        var checksum: String
        var weight: Double
        var timezone: String
        var status: RollingPriorityGroupStatus

        init(code: String, title: String, checksum: String, weight: Double, timezone: String, status: RollingPriorityGroupStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.weight = weight
            self.timezone = timezone
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

        func canMoveTo(_ next: RollingPriorityGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingPriorityGroupStatus.expired
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingPriorityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling priority group") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> RollingPriorityGroup {
            return RollingPriorityGroup(
                code: code,
                title: title,
                checksum: checksum,
                weight: weight,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling priority group in status requested.
    static func newRollingPriorityGroup(_ code: String, title: String) -> RollingPriorityGroup {
        return RollingPriorityGroup(
            code: code,
            title: title,
            checksum: "",
            weight: 0.0,
            timezone: "",
            status: RollingPriorityGroupStatus.requested
        )
    }
}
