import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist override is in its life cycle.
    enum WorklistOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One worklist override, with what the planners need to act on it.
    final class WorklistOverride {
        var code: String
        var title: String
        var attempts: Int
        var startsAt: Int
        var locale: String
        var reviewer: String
        var limit: Int
        var status: WorklistOverrideStatus

        init(code: String, title: String, attempts: Int, startsAt: Int, locale: String, reviewer: String, limit: Int, status: WorklistOverrideStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.startsAt = startsAt
            self.locale = locale
            self.reviewer = reviewer
            self.limit = limit
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

        func canMoveTo(_ next: WorklistOverrideStatus) -> Bool {
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

        func moveTo(_ next: WorklistOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistOverride {
            return WorklistOverride(
                code: code,
                title: title,
                attempts: attempts,
                startsAt: startsAt,
                locale: locale,
                reviewer: reviewer,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a worklist override in status requested.
    static func newWorklistOverride(_ code: String, title: String) -> WorklistOverride {
        return WorklistOverride(
            code: code,
            title: title,
            attempts: 0,
            startsAt: 0,
            locale: "",
            reviewer: "",
            limit: 0,
            status: WorklistOverrideStatus.requested
        )
    }
}
