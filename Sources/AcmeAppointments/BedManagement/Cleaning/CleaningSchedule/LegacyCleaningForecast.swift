import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy cleaning forecast is in its life cycle.
    enum LegacyCleaningForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy cleaning forecast and its current status.
    final class LegacyCleaningForecast {
        var code: String
        var title: String
        var encounterID: String
        var priority: Int
        var createdAt: Int
        var specialty: String
        var revision: Int
        var tags: [String]
        var endsAt: Int
        var phone: String
        var retries: Int
        var status: LegacyCleaningForecastStatus

        init(code: String, title: String, encounterID: String, priority: Int, createdAt: Int, specialty: String, revision: Int, tags: [String], endsAt: Int, phone: String, retries: Int, status: LegacyCleaningForecastStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.priority = priority
            self.createdAt = createdAt
            self.specialty = specialty
            self.revision = revision
            self.tags = tags
            self.endsAt = endsAt
            self.phone = phone
            self.retries = retries
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

        func canMoveTo(_ next: LegacyCleaningForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyCleaningForecastStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyCleaningForecastStatus.reopened
            case .reopened:
                return next == LegacyCleaningForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCleaningForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy cleaning forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return ((Double(retries) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCleaningForecast {
            return LegacyCleaningForecast(
                code: code,
                title: title,
                encounterID: encounterID,
                priority: priority,
                createdAt: createdAt,
                specialty: specialty,
                revision: revision,
                tags: tags,
                endsAt: endsAt,
                phone: phone,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy cleaning forecast in status open.
    static func newLegacyCleaningForecast(_ code: String, title: String) -> LegacyCleaningForecast {
        return LegacyCleaningForecast(
            code: code,
            title: title,
            encounterID: "",
            priority: 0,
            createdAt: 0,
            specialty: "",
            revision: 0,
            tags: [],
            endsAt: 0,
            phone: "",
            retries: 0,
            status: LegacyCleaningForecastStatus.`open`
        )
    }
}
