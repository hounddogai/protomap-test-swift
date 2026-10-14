import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall policy is in its life cycle.
    enum PrimaryRecallPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One primary recall policy, with what the planners need to act on it.
    final class PrimaryRecallPolicy {
        var code: String
        var label: String
        var timezone: String
        var category: String
        var score: Double
        var archived: Bool
        var active: Bool
        var currency: String
        var status: PrimaryRecallPolicyStatus

        init(code: String, label: String, timezone: String, category: String, score: Double, archived: Bool, active: Bool, currency: String, status: PrimaryRecallPolicyStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.category = category
            self.score = score
            self.archived = archived
            self.active = active
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryRecallPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PrimaryRecallPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRecallPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PrimaryRecallPolicy {
            return PrimaryRecallPolicy(
                code: code,
                label: label,
                timezone: timezone,
                category: category,
                score: score,
                archived: archived,
                active: active,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary recall policy in status planned.
    static func newPrimaryRecallPolicy(_ code: String, label: String) -> PrimaryRecallPolicy {
        return PrimaryRecallPolicy(
            code: code,
            label: label,
            timezone: "",
            category: "",
            score: 0.0,
            archived: false,
            active: false,
            currency: "",
            status: PrimaryRecallPolicyStatus.planned
        )
    }
}
