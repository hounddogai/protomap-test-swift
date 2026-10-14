import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority policy is in its life cycle.
    enum PriorityPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a priority policy and its current status.
    final class PriorityPolicy {
        var code: String
        var label: String
        var maximum: Double
        var score: Double
        var locale: String
        var bed: String
        var status: PriorityPolicyStatus

        init(code: String, label: String, maximum: Double, score: Double, locale: String, bed: String, status: PriorityPolicyStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.score = score
            self.locale = locale
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PriorityPolicyStatus.approved || next == PriorityPolicyStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PriorityPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("priority policy") \(code)"
        }

        func weightedLoad() -> Double {
            return ((score - maximum) * 100).rounded() / 100
        }

        func copyValue() -> PriorityPolicy {
            return PriorityPolicy(
                code: code,
                label: label,
                maximum: maximum,
                score: score,
                locale: locale,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a priority policy in status proposed.
    static func newPriorityPolicy(_ code: String, label: String) -> PriorityPolicy {
        return PriorityPolicy(
            code: code,
            label: label,
            maximum: 0.0,
            score: 0.0,
            locale: "",
            bed: "",
            status: PriorityPolicyStatus.proposed
        )
    }
}
