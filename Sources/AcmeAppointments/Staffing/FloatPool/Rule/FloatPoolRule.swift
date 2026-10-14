import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool rule is in its life cycle.
    enum FloatPoolRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a float pool rule and its current status.
    final class FloatPoolRule {
        var code: String
        var title: String
        var copay: Double
        var budget: Double
        var allergy: String
        var bed: String
        var status: FloatPoolRuleStatus

        init(code: String, title: String, copay: Double, budget: Double, allergy: String, bed: String, status: FloatPoolRuleStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.budget = budget
            self.allergy = allergy
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

        func canMoveTo(_ next: FloatPoolRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: FloatPoolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return (copay * budget * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolRule {
            return FloatPoolRule(
                code: code,
                title: title,
                copay: copay,
                budget: budget,
                allergy: allergy,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool rule in status created.
    static func newFloatPoolRule(_ code: String, title: String) -> FloatPoolRule {
        return FloatPoolRule(
            code: code,
            title: title,
            copay: 0.0,
            budget: 0.0,
            allergy: "",
            bed: "",
            status: FloatPoolRuleStatus.created
        )
    }
}
