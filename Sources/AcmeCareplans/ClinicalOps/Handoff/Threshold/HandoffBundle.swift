import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff bundle is in its life cycle.
    enum HandoffBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A handoff bundle as the handoff team keeps it.
    final class HandoffBundle {
        var code: String
        var title: String
        var maximum: Double
        var priority: Int
        var currency: String
        var limit: Int
        var margin: Double
        var amount: Double
        var specialty: String
        var reviewer: String
        var sequence: Int
        var status: HandoffBundleStatus

        init(code: String, title: String, maximum: Double, priority: Int, currency: String, limit: Int, margin: Double, amount: Double, specialty: String, reviewer: String, sequence: Int, status: HandoffBundleStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.priority = priority
            self.currency = currency
            self.limit = limit
            self.margin = margin
            self.amount = amount
            self.specialty = specialty
            self.reviewer = reviewer
            self.sequence = sequence
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

        func canMoveTo(_ next: HandoffBundleStatus) -> Bool {
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
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == HandoffBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("handoff bundle") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((amount - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffBundle {
            return HandoffBundle(
                code: code,
                title: title,
                maximum: maximum,
                priority: priority,
                currency: currency,
                limit: limit,
                margin: margin,
                amount: amount,
                specialty: specialty,
                reviewer: reviewer,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff bundle in status open.
    static func newHandoffBundle(_ code: String, title: String) -> HandoffBundle {
        return HandoffBundle(
            code: code,
            title: title,
            maximum: 0.0,
            priority: 0,
            currency: "",
            limit: 0,
            margin: 0.0,
            amount: 0.0,
            specialty: "",
            reviewer: "",
            sequence: 0,
            status: HandoffBundleStatus.`open`
        )
    }
}
