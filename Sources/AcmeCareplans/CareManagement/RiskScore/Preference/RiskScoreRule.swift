import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score rule is in its life cycle.
    enum RiskScoreRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A risk score rule as the risk score team keeps it.
    final class RiskScoreRule {
        var code: String
        var label: String
        var visible: Bool
        var unit: String
        var sequence: Int
        var locale: String
        var encounterID: String
        var phone: String
        var attempts: Int
        var weight: Double
        var diagnosisCode: String
        var status: RiskScoreRuleStatus

        init(code: String, label: String, visible: Bool, unit: String, sequence: Int, locale: String, encounterID: String, phone: String, attempts: Int, weight: Double, diagnosisCode: String, status: RiskScoreRuleStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.unit = unit
            self.sequence = sequence
            self.locale = locale
            self.encounterID = encounterID
            self.phone = phone
            self.attempts = attempts
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RiskScoreRuleStatus.failed
            case .running:
                return next == RiskScoreRuleStatus.failed
            case .done:
                return next == RiskScoreRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return (Double(attempts) * weight * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreRule {
            return RiskScoreRule(
                code: code,
                label: label,
                visible: visible,
                unit: unit,
                sequence: sequence,
                locale: locale,
                encounterID: encounterID,
                phone: phone,
                attempts: attempts,
                weight: weight,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score rule in status new.
    static func newRiskScoreRule(_ code: String, label: String) -> RiskScoreRule {
        return RiskScoreRule(
            code: code,
            label: label,
            visible: false,
            unit: "",
            sequence: 0,
            locale: "",
            encounterID: "",
            phone: "",
            attempts: 0,
            weight: 0.0,
            diagnosisCode: "",
            status: RiskScoreRuleStatus.new
        )
    }
}
