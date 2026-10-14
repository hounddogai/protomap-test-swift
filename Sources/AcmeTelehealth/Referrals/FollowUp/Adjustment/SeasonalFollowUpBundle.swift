import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal follow up bundle is in its life cycle.
    enum SeasonalFollowUpBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One seasonal follow up bundle, with what the planners need to act on it.
    final class SeasonalFollowUpBundle {
        var code: String
        var name: String
        var locale: String
        var budget: Double
        var specialty: String
        var ownerID: String
        var country: String
        var active: Bool
        var startsAt: Int
        var summary: String
        var status: SeasonalFollowUpBundleStatus

        init(code: String, name: String, locale: String, budget: Double, specialty: String, ownerID: String, country: String, active: Bool, startsAt: Int, summary: String, status: SeasonalFollowUpBundleStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.budget = budget
            self.specialty = specialty
            self.ownerID = ownerID
            self.country = country
            self.active = active
            self.startsAt = startsAt
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalFollowUpBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalFollowUpBundleStatus.rejected || next == SeasonalFollowUpBundleStatus.withdrawn
            case .approved:
                return next == SeasonalFollowUpBundleStatus.rejected || next == SeasonalFollowUpBundleStatus.withdrawn
            case .rejected:
                return next == SeasonalFollowUpBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalFollowUpBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal follow up bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(startsAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalFollowUpBundle {
            return SeasonalFollowUpBundle(
                code: code,
                name: name,
                locale: locale,
                budget: budget,
                specialty: specialty,
                ownerID: ownerID,
                country: country,
                active: active,
                startsAt: startsAt,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a seasonal follow up bundle in status proposed.
    static func newSeasonalFollowUpBundle(_ code: String, name: String) -> SeasonalFollowUpBundle {
        return SeasonalFollowUpBundle(
            code: code,
            name: name,
            locale: "",
            budget: 0.0,
            specialty: "",
            ownerID: "",
            country: "",
            active: false,
            startsAt: 0,
            summary: "",
            status: SeasonalFollowUpBundleStatus.proposed
        )
    }
}
