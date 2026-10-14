import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range preference is in its life cycle.
    enum ReferenceRangePreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a reference range preference and its current status.
    final class ReferenceRangePreference {
        var code: String
        var title: String
        var locale: String
        var archived: Bool
        var procedureCode: String
        var score: Double
        var status: ReferenceRangePreferenceStatus

        init(code: String, title: String, locale: String, archived: Bool, procedureCode: String, score: Double, status: ReferenceRangePreferenceStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.archived = archived
            self.procedureCode = procedureCode
            self.score = score
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

        func canMoveTo(_ next: ReferenceRangePreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReferenceRangePreferenceStatus.reopened
            case .resolved:
                return next == ReferenceRangePreferenceStatus.reopened
            case .reopened:
                return next == ReferenceRangePreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ReferenceRangePreference {
            return ReferenceRangePreference(
                code: code,
                title: title,
                locale: locale,
                archived: archived,
                procedureCode: procedureCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a reference range preference in status open.
    static func newReferenceRangePreference(_ code: String, title: String) -> ReferenceRangePreference {
        return ReferenceRangePreference(
            code: code,
            title: title,
            locale: "",
            archived: false,
            procedureCode: "",
            score: 0.0,
            status: ReferenceRangePreferenceStatus.`open`
        )
    }
}
