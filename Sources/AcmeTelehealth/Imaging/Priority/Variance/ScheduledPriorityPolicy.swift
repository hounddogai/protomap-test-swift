import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority policy is in its life cycle.
    enum ScheduledPriorityPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a scheduled priority policy and its current status.
    final class ScheduledPriorityPolicy {
        var code: String
        var label: String
        var source: String
        var summary: String
        var amount: Double
        var allergy: String
        var margin: Double
        var createdAt: Int
        var status: ScheduledPriorityPolicyStatus

        init(code: String, label: String, source: String, summary: String, amount: Double, allergy: String, margin: Double, createdAt: Int, status: ScheduledPriorityPolicyStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.summary = summary
            self.amount = amount
            self.allergy = allergy
            self.margin = margin
            self.createdAt = createdAt
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

        func canMoveTo(_ next: ScheduledPriorityPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ScheduledPriorityPolicyStatus.completed
            case .inProgress:
                return next == ScheduledPriorityPolicyStatus.completed || next == ScheduledPriorityPolicyStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ScheduledPriorityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((amount + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPriorityPolicy {
            return ScheduledPriorityPolicy(
                code: code,
                label: label,
                source: source,
                summary: summary,
                amount: amount,
                allergy: allergy,
                margin: margin,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled priority policy in status planned.
    static func newScheduledPriorityPolicy(_ code: String, label: String) -> ScheduledPriorityPolicy {
        return ScheduledPriorityPolicy(
            code: code,
            label: label,
            source: "",
            summary: "",
            amount: 0.0,
            allergy: "",
            margin: 0.0,
            createdAt: 0,
            status: ScheduledPriorityPolicyStatus.planned
        )
    }
}
