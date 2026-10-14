import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census quota is in its life cycle.
    enum CensusQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A census quota. Its code is unique within a tenant.
    final class CensusQuota {
        var code: String
        var title: String
        var budget: Double
        var country: String
        var timezone: String
        var attempts: Int
        var windowDays: Int
        var contactEmail: String
        var startsAt: Int
        var status: CensusQuotaStatus

        init(code: String, title: String, budget: Double, country: String, timezone: String, attempts: Int, windowDays: Int, contactEmail: String, startsAt: Int, status: CensusQuotaStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.country = country
            self.timezone = timezone
            self.attempts = attempts
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == CensusQuotaStatus.suspended
            case .pending:
                return next == CensusQuotaStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CensusQuotaStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("census quota") \(code)"
        }

        func netVolume() -> Double {
            return ((budget - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CensusQuota {
            return CensusQuota(
                code: code,
                title: title,
                budget: budget,
                country: country,
                timezone: timezone,
                attempts: attempts,
                windowDays: windowDays,
                contactEmail: contactEmail,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a census quota in status draft.
    static func newCensusQuota(_ code: String, title: String) -> CensusQuota {
        return CensusQuota(
            code: code,
            title: title,
            budget: 0.0,
            country: "",
            timezone: "",
            attempts: 0,
            windowDays: 0,
            contactEmail: "",
            startsAt: 0,
            status: CensusQuotaStatus.draft
        )
    }
}
