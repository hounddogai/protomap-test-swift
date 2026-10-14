import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional census preference is in its life cycle.
    enum RegionalCensusPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional census preference and its current status.
    final class RegionalCensusPreference {
        var code: String
        var title: String
        var retries: Int
        var summary: String
        var ceiling: Double
        var expiresAt: Int
        var durationMinutes: Int
        var active: Bool
        var startsAt: Int
        var region: String
        var status: RegionalCensusPreferenceStatus

        init(code: String, title: String, retries: Int, summary: String, ceiling: Double, expiresAt: Int, durationMinutes: Int, active: Bool, startsAt: Int, region: String, status: RegionalCensusPreferenceStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.summary = summary
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.durationMinutes = durationMinutes
            self.active = active
            self.startsAt = startsAt
            self.region = region
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

        func canMoveTo(_ next: RegionalCensusPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalCensusPreferenceStatus.reopened || next == RegionalCensusPreferenceStatus.archived
            case .inReview:
                return next == RegionalCensusPreferenceStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalCensusPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional census preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedLoad() -> Double {
            return ((ceiling - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCensusPreference {
            return RegionalCensusPreference(
                code: code,
                title: title,
                retries: retries,
                summary: summary,
                ceiling: ceiling,
                expiresAt: expiresAt,
                durationMinutes: durationMinutes,
                active: active,
                startsAt: startsAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional census preference in status open.
    static func newRegionalCensusPreference(_ code: String, title: String) -> RegionalCensusPreference {
        return RegionalCensusPreference(
            code: code,
            title: title,
            retries: 0,
            summary: "",
            ceiling: 0.0,
            expiresAt: 0,
            durationMinutes: 0,
            active: false,
            startsAt: 0,
            region: "",
            status: RegionalCensusPreferenceStatus.`open`
        )
    }
}
