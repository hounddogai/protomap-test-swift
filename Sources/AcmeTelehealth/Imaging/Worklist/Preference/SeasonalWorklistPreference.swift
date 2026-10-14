import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal worklist preference is in its life cycle.
    enum SeasonalWorklistPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal worklist preference, with what the planners need to act on it.
    final class SeasonalWorklistPreference {
        var code: String
        var title: String
        var procedureCode: String
        var limit: Int
        var ceiling: Double
        var ratio: Double
        var channel: String
        var country: String
        var revision: Int
        var contactEmail: String
        var archived: Bool
        var status: SeasonalWorklistPreferenceStatus

        init(code: String, title: String, procedureCode: String, limit: Int, ceiling: Double, ratio: Double, channel: String, country: String, revision: Int, contactEmail: String, archived: Bool, status: SeasonalWorklistPreferenceStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.limit = limit
            self.ceiling = ceiling
            self.ratio = ratio
            self.channel = channel
            self.country = country
            self.revision = revision
            self.contactEmail = contactEmail
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalWorklistPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalWorklistPreferenceStatus.done
            case .running:
                return next == SeasonalWorklistPreferenceStatus.done || next == SeasonalWorklistPreferenceStatus.failed
            case .done:
                return next == SeasonalWorklistPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalWorklistPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal worklist preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((ratio - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWorklistPreference {
            return SeasonalWorklistPreference(
                code: code,
                title: title,
                procedureCode: procedureCode,
                limit: limit,
                ceiling: ceiling,
                ratio: ratio,
                channel: channel,
                country: country,
                revision: revision,
                contactEmail: contactEmail,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal worklist preference in status new.
    static func newSeasonalWorklistPreference(_ code: String, title: String) -> SeasonalWorklistPreference {
        return SeasonalWorklistPreference(
            code: code,
            title: title,
            procedureCode: "",
            limit: 0,
            ceiling: 0.0,
            ratio: 0.0,
            channel: "",
            country: "",
            revision: 0,
            contactEmail: "",
            archived: false,
            status: SeasonalWorklistPreferenceStatus.new
        )
    }
}
