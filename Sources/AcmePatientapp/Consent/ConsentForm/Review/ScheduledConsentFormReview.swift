import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled consent form review is in its life cycle.
    enum ScheduledConsentFormReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled consent form review as the consent form team keeps it.
    final class ScheduledConsentFormReview {
        var code: String
        var name: String
        var active: Bool
        var version: Int
        var summary: String
        var cost: Double
        var quantity: Int
        var status: ScheduledConsentFormReviewStatus

        init(code: String, name: String, active: Bool, version: Int, summary: String, cost: Double, quantity: Int, status: ScheduledConsentFormReviewStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.version = version
            self.summary = summary
            self.cost = cost
            self.quantity = quantity
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

        func canMoveTo(_ next: ScheduledConsentFormReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledConsentFormReviewStatus.resolved || next == ScheduledConsentFormReviewStatus.archived
            case .inReview:
                return next == ScheduledConsentFormReviewStatus.reopened || next == ScheduledConsentFormReviewStatus.archived
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: ScheduledConsentFormReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled consent form review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return (cost * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledConsentFormReview {
            return ScheduledConsentFormReview(
                code: code,
                name: name,
                active: active,
                version: version,
                summary: summary,
                cost: cost,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled consent form review in status open.
    static func newScheduledConsentFormReview(_ code: String, name: String) -> ScheduledConsentFormReview {
        return ScheduledConsentFormReview(
            code: code,
            name: name,
            active: false,
            version: 0,
            summary: "",
            cost: 0.0,
            quantity: 0,
            status: ScheduledConsentFormReviewStatus.`open`
        )
    }
}
