import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted read preference is in its life cycle.
    enum WeightedReadPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted read preference, with what the planners need to act on it.
    final class WeightedReadPreference {
        var code: String
        var title: String
        var country: String
        var graceDays: Int
        var specialty: String
        var status: WeightedReadPreferenceStatus

        init(code: String, title: String, country: String, graceDays: Int, specialty: String, status: WeightedReadPreferenceStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.graceDays = graceDays
            self.specialty = specialty
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

        func canMoveTo(_ next: WeightedReadPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedReadPreferenceStatus.archived
            case .resolved:
                return next == WeightedReadPreferenceStatus.reopened || next == WeightedReadPreferenceStatus.archived
            case .reopened:
                return next == WeightedReadPreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReadPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted read preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> WeightedReadPreference {
            return WeightedReadPreference(
                code: code,
                title: title,
                country: country,
                graceDays: graceDays,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted read preference in status open.
    static func newWeightedReadPreference(_ code: String, title: String) -> WeightedReadPreference {
        return WeightedReadPreference(
            code: code,
            title: title,
            country: "",
            graceDays: 0,
            specialty: "",
            status: WeightedReadPreferenceStatus.`open`
        )
    }
}
