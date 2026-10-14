import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure plan is in its life cycle.
    enum DisclosurePlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A disclosure plan as the disclosure team keeps it.
    final class DisclosurePlan {
        var code: String
        var title: String
        var currency: String
        var revision: Int
        var updatedAt: Int
        var cost: Double
        var locale: String
        var summary: String
        var status: DisclosurePlanStatus

        init(code: String, title: String, currency: String, revision: Int, updatedAt: Int, cost: Double, locale: String, summary: String, status: DisclosurePlanStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.revision = revision
            self.updatedAt = updatedAt
            self.cost = cost
            self.locale = locale
            self.summary = summary
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

        func canMoveTo(_ next: DisclosurePlanStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DisclosurePlanStatus.draining || next == DisclosurePlanStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DisclosurePlanStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosurePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("disclosure plan") \(code)"
        }

        func netValue() -> Double {
            return ((Double(revision) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosurePlan {
            return DisclosurePlan(
                code: code,
                title: title,
                currency: currency,
                revision: revision,
                updatedAt: updatedAt,
                cost: cost,
                locale: locale,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a disclosure plan in status idle.
    static func newDisclosurePlan(_ code: String, title: String) -> DisclosurePlan {
        return DisclosurePlan(
            code: code,
            title: title,
            currency: "",
            revision: 0,
            updatedAt: 0,
            cost: 0.0,
            locale: "",
            summary: "",
            status: DisclosurePlanStatus.idle
        )
    }
}
