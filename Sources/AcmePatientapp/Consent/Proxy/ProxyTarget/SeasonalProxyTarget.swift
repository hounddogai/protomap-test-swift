import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal proxy target is in its life cycle.
    enum SeasonalProxyTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal proxy target, with what the planners need to act on it.
    final class SeasonalProxyTarget {
        var code: String
        var name: String
        var version: Int
        var acuity: Int
        var graceDays: Int
        var status: SeasonalProxyTargetStatus

        init(code: String, name: String, version: Int, acuity: Int, graceDays: Int, status: SeasonalProxyTargetStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.acuity = acuity
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalProxyTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SeasonalProxyTargetStatus.reopened || next == SeasonalProxyTargetStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalProxyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal proxy target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(version) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalProxyTarget {
            return SeasonalProxyTarget(
                code: code,
                name: name,
                version: version,
                acuity: acuity,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal proxy target in status open.
    static func newSeasonalProxyTarget(_ code: String, name: String) -> SeasonalProxyTarget {
        return SeasonalProxyTarget(
            code: code,
            name: name,
            version: 0,
            acuity: 0,
            graceDays: 0,
            status: SeasonalProxyTargetStatus.`open`
        )
    }
}
