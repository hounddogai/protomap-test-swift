import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted slot preference is in its life cycle.
    enum WeightedSlotPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One weighted slot preference, with what the planners need to act on it.
    final class WeightedSlotPreference {
        var code: String
        var title: String
        var patientRef: String
        var locale: String
        var tags: [String]
        var contactEmail: String
        var summary: String
        var score: Double
        var status: WeightedSlotPreferenceStatus

        init(code: String, title: String, patientRef: String, locale: String, tags: [String], contactEmail: String, summary: String, score: Double, status: WeightedSlotPreferenceStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.locale = locale
            self.tags = tags
            self.contactEmail = contactEmail
            self.summary = summary
            self.score = score
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

        func canMoveTo(_ next: WeightedSlotPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WeightedSlotPreferenceStatus.active || next == WeightedSlotPreferenceStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedSlotPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSlotPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted slot preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WeightedSlotPreference {
            return WeightedSlotPreference(
                code: code,
                title: title,
                patientRef: patientRef,
                locale: locale,
                tags: tags,
                contactEmail: contactEmail,
                summary: summary,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted slot preference in status draft.
    static func newWeightedSlotPreference(_ code: String, title: String) -> WeightedSlotPreference {
        return WeightedSlotPreference(
            code: code,
            title: title,
            patientRef: "",
            locale: "",
            tags: [],
            contactEmail: "",
            summary: "",
            score: 0.0,
            status: WeightedSlotPreferenceStatus.draft
        )
    }
}
