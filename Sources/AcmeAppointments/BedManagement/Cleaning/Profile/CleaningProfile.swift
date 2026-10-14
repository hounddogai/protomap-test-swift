import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning profile is in its life cycle.
    enum CleaningProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One cleaning profile, with what the planners need to act on it.
    final class CleaningProfile {
        var code: String
        var name: String
        var graceDays: Int
        var pinned: Bool
        var version: Int
        var minimum: Double
        var status: CleaningProfileStatus

        init(code: String, name: String, graceDays: Int, pinned: Bool, version: Int, minimum: Double, status: CleaningProfileStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.pinned = pinned
            self.version = version
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == CleaningProfileStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CleaningProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("cleaning profile") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(version) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CleaningProfile {
            return CleaningProfile(
                code: code,
                name: name,
                graceDays: graceDays,
                pinned: pinned,
                version: version,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning profile in status idle.
    static func newCleaningProfile(_ code: String, name: String) -> CleaningProfile {
        return CleaningProfile(
            code: code,
            name: name,
            graceDays: 0,
            pinned: false,
            version: 0,
            minimum: 0.0,
            status: CleaningProfileStatus.idle
        )
    }
}
