import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal proxy group is in its life cycle.
    enum SeasonalProxyGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal proxy group, with what the planners need to act on it.
    final class SeasonalProxyGroup {
        var code: String
        var title: String
        var active: Bool
        var weight: Double
        var updatedAt: Int
        var summary: String
        var refills: Int
        var pinned: Bool
        var status: SeasonalProxyGroupStatus

        init(code: String, title: String, active: Bool, weight: Double, updatedAt: Int, summary: String, refills: Int, pinned: Bool, status: SeasonalProxyGroupStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.weight = weight
            self.updatedAt = updatedAt
            self.summary = summary
            self.refills = refills
            self.pinned = pinned
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

        func canMoveTo(_ next: SeasonalProxyGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalProxyGroupStatus.granted || next == SeasonalProxyGroupStatus.expired
            case .granted:
                return next == SeasonalProxyGroupStatus.revoked || next == SeasonalProxyGroupStatus.expired
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

        func moveTo(_ next: SeasonalProxyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal proxy group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal proxy group") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(updatedAt) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalProxyGroup {
            return SeasonalProxyGroup(
                code: code,
                title: title,
                active: active,
                weight: weight,
                updatedAt: updatedAt,
                summary: summary,
                refills: refills,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal proxy group in status requested.
    static func newSeasonalProxyGroup(_ code: String, title: String) -> SeasonalProxyGroup {
        return SeasonalProxyGroup(
            code: code,
            title: title,
            active: false,
            weight: 0.0,
            updatedAt: 0,
            summary: "",
            refills: 0,
            pinned: false,
            status: SeasonalProxyGroupStatus.requested
        )
    }
}
