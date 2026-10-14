import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy acuity plan summary is in its life cycle.
    enum LegacyAcuityPlanSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy acuity plan summary and its current status.
    final class LegacyAcuityPlanSummary {
        var code: String
        var title: String
        var contactEmail: String
        var segment: String
        var attributes: [String: String]
        var category: String
        var attempts: Int
        var status: LegacyAcuityPlanSummaryStatus

        init(code: String, title: String, contactEmail: String, segment: String, attributes: [String: String], category: String, attempts: Int, status: LegacyAcuityPlanSummaryStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.segment = segment
            self.attributes = attributes
            self.category = category
            self.attempts = attempts
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

        func canMoveTo(_ next: LegacyAcuityPlanSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyAcuityPlanSummaryStatus.active
            case .pending:
                return next == LegacyAcuityPlanSummaryStatus.suspended || next == LegacyAcuityPlanSummaryStatus.closed
            case .active:
                return next == LegacyAcuityPlanSummaryStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyAcuityPlanSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy acuity plan summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> LegacyAcuityPlanSummary {
            return LegacyAcuityPlanSummary(
                code: code,
                title: title,
                contactEmail: contactEmail,
                segment: segment,
                attributes: attributes,
                category: category,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy acuity plan summary in status draft.
    static func newLegacyAcuityPlanSummary(_ code: String, title: String) -> LegacyAcuityPlanSummary {
        return LegacyAcuityPlanSummary(
            code: code,
            title: title,
            contactEmail: "",
            segment: "",
            attributes: [:],
            category: "",
            attempts: 0,
            status: LegacyAcuityPlanSummaryStatus.draft
        )
    }
}
