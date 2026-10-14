import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled outreach request is in its life cycle.
    enum ScheduledOutreachRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled outreach request as the outreach team keeps it.
    final class ScheduledOutreachRequest {
        var code: String
        var name: String
        var title: String
        var timezone: String
        var bed: String
        var locale: String
        var reviewer: String
        var amount: Double
        var status: ScheduledOutreachRequestStatus

        init(code: String, name: String, title: String, timezone: String, bed: String, locale: String, reviewer: String, amount: Double, status: ScheduledOutreachRequestStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.timezone = timezone
            self.bed = bed
            self.locale = locale
            self.reviewer = reviewer
            self.amount = amount
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

        func canMoveTo(_ next: ScheduledOutreachRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledOutreachRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled outreach request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled outreach request") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ScheduledOutreachRequest {
            return ScheduledOutreachRequest(
                code: code,
                name: name,
                title: title,
                timezone: timezone,
                bed: bed,
                locale: locale,
                reviewer: reviewer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled outreach request in status draft.
    static func newScheduledOutreachRequest(_ code: String, name: String) -> ScheduledOutreachRequest {
        return ScheduledOutreachRequest(
            code: code,
            name: name,
            title: "",
            timezone: "",
            bed: "",
            locale: "",
            reviewer: "",
            amount: 0.0,
            status: ScheduledOutreachRequestStatus.draft
        )
    }
}
