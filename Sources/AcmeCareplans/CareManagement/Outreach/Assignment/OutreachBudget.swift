import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach budget is in its life cycle.
    enum OutreachBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a outreach budget and its current status.
    final class OutreachBudget {
        var code: String
        var title: String
        var reviewer: String
        var timezone: String
        var locale: String
        var amount: Double
        var specialty: String
        var checksum: String
        var region: String
        var category: String
        var status: OutreachBudgetStatus

        init(code: String, title: String, reviewer: String, timezone: String, locale: String, amount: Double, specialty: String, checksum: String, region: String, category: String, status: OutreachBudgetStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.timezone = timezone
            self.locale = locale
            self.amount = amount
            self.specialty = specialty
            self.checksum = checksum
            self.region = region
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == OutreachBudgetStatus.warming || next == OutreachBudgetStatus.draining
            case .warming:
                return next == OutreachBudgetStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: OutreachBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("outreach budget") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OutreachBudget {
            return OutreachBudget(
                code: code,
                title: title,
                reviewer: reviewer,
                timezone: timezone,
                locale: locale,
                amount: amount,
                specialty: specialty,
                checksum: checksum,
                region: region,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a outreach budget in status idle.
    static func newOutreachBudget(_ code: String, title: String) -> OutreachBudget {
        return OutreachBudget(
            code: code,
            title: title,
            reviewer: "",
            timezone: "",
            locale: "",
            amount: 0.0,
            specialty: "",
            checksum: "",
            region: "",
            category: "",
            status: OutreachBudgetStatus.idle
        )
    }
}
