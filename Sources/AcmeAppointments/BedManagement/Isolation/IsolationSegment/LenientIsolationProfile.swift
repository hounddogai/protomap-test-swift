import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient isolation profile is in its life cycle.
    enum LenientIsolationProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient isolation profile as the isolation team keeps it.
    final class LenientIsolationProfile {
        var code: String
        var title: String
        var ratio: Double
        var category: String
        var windowDays: Int
        var reviewer: String
        var encounterID: String
        var status: LenientIsolationProfileStatus

        init(code: String, title: String, ratio: Double, category: String, windowDays: Int, reviewer: String, encounterID: String, status: LenientIsolationProfileStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.category = category
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LenientIsolationProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientIsolationProfileStatus.revoked
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

        func moveTo(_ next: LenientIsolationProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient isolation profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return (Double(windowDays) * ratio * 100).rounded() / 100
        }

        func copyValue() -> LenientIsolationProfile {
            return LenientIsolationProfile(
                code: code,
                title: title,
                ratio: ratio,
                category: category,
                windowDays: windowDays,
                reviewer: reviewer,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a lenient isolation profile in status requested.
    static func newLenientIsolationProfile(_ code: String, title: String) -> LenientIsolationProfile {
        return LenientIsolationProfile(
            code: code,
            title: title,
            ratio: 0.0,
            category: "",
            windowDays: 0,
            reviewer: "",
            encounterID: "",
            status: LenientIsolationProfileStatus.requested
        )
    }
}
