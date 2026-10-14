import AcmePlatform
import Foundation

extension Consent {
    /// Where a language schedule is in its life cycle.
    enum LanguageScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One language schedule, with what the planners need to act on it.
    final class LanguageSchedule {
        var code: String
        var label: String
        var summary: String
        var limit: Int
        var startsAt: Int
        var acuity: Int
        var updatedAt: Int
        var currency: String
        var status: LanguageScheduleStatus

        init(code: String, label: String, summary: String, limit: Int, startsAt: Int, acuity: Int, updatedAt: Int, currency: String, status: LanguageScheduleStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.limit = limit
            self.startsAt = startsAt
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.currency = currency
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

        func canMoveTo(_ next: LanguageScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LanguageScheduleStatus.resolved
            case .inReview:
                return next == LanguageScheduleStatus.reopened
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: LanguageScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("language schedule") \(code)"
        }

        func netLoad() -> Double {
            return (Double(startsAt) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> LanguageSchedule {
            return LanguageSchedule(
                code: code,
                label: label,
                summary: summary,
                limit: limit,
                startsAt: startsAt,
                acuity: acuity,
                updatedAt: updatedAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language schedule in status open.
    static func newLanguageSchedule(_ code: String, label: String) -> LanguageSchedule {
        return LanguageSchedule(
            code: code,
            label: label,
            summary: "",
            limit: 0,
            startsAt: 0,
            acuity: 0,
            updatedAt: 0,
            currency: "",
            status: LanguageScheduleStatus.`open`
        )
    }
}
