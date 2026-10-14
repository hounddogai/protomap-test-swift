import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal isolation rule is in its life cycle.
    enum SeasonalIsolationRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a seasonal isolation rule and its current status.
    final class SeasonalIsolationRule {
        var code: String
        var label: String
        var allergy: String
        var diagnosisCode: String
        var copay: Double
        var status: SeasonalIsolationRuleStatus

        init(code: String, label: String, allergy: String, diagnosisCode: String, copay: Double, status: SeasonalIsolationRuleStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.diagnosisCode = diagnosisCode
            self.copay = copay
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

        func canMoveTo(_ next: SeasonalIsolationRuleStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalIsolationRuleStatus.validated
            case .validated:
                return next == SeasonalIsolationRuleStatus.published || next == SeasonalIsolationRuleStatus.retired
            case .published:
                return next == SeasonalIsolationRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalIsolationRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal isolation rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> SeasonalIsolationRule {
            return SeasonalIsolationRule(
                code: code,
                label: label,
                allergy: allergy,
                diagnosisCode: diagnosisCode,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal isolation rule in status created.
    static func newSeasonalIsolationRule(_ code: String, label: String) -> SeasonalIsolationRule {
        return SeasonalIsolationRule(
            code: code,
            label: label,
            allergy: "",
            diagnosisCode: "",
            copay: 0.0,
            status: SeasonalIsolationRuleStatus.created
        )
    }
}
