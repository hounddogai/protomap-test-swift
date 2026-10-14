import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding rule is in its life cycle.
    enum RoundingRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rounding rule. Its code is unique within a tenant.
    final class RoundingRule {
        var code: String
        var label: String
        var encounterID: String
        var amount: Double
        var segment: String
        var ratio: Double
        var updatedAt: Int
        var bed: String
        var status: RoundingRuleStatus

        init(code: String, label: String, encounterID: String, amount: Double, segment: String, ratio: Double, updatedAt: Int, bed: String, status: RoundingRuleStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.amount = amount
            self.segment = segment
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RoundingRuleStatus.retired
            case .published:
                return next == RoundingRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return ((amount - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RoundingRule {
            return RoundingRule(
                code: code,
                label: label,
                encounterID: encounterID,
                amount: amount,
                segment: segment,
                ratio: ratio,
                updatedAt: updatedAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rounding rule in status created.
    static func newRoundingRule(_ code: String, label: String) -> RoundingRule {
        return RoundingRule(
            code: code,
            label: label,
            encounterID: "",
            amount: 0.0,
            segment: "",
            ratio: 0.0,
            updatedAt: 0,
            bed: "",
            status: RoundingRuleStatus.created
        )
    }
}
