import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form rule is in its life cycle.
    enum ConsentFormRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A consent form rule. Its code is unique within a tenant.
    final class ConsentFormRule {
        var code: String
        var name: String
        var clinicianID: String
        var visible: Bool
        var locale: String
        var score: Double
        var status: ConsentFormRuleStatus

        init(code: String, name: String, clinicianID: String, visible: Bool, locale: String, score: Double, status: ConsentFormRuleStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.visible = visible
            self.locale = locale
            self.score = score
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

        func canMoveTo(_ next: ConsentFormRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
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
                return next == ConsentFormRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form rule") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ConsentFormRule {
            return ConsentFormRule(
                code: code,
                name: name,
                clinicianID: clinicianID,
                visible: visible,
                locale: locale,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a consent form rule in status created.
    static func newConsentFormRule(_ code: String, name: String) -> ConsentFormRule {
        return ConsentFormRule(
            code: code,
            name: name,
            clinicianID: "",
            visible: false,
            locale: "",
            score: 0.0,
            status: ConsentFormRuleStatus.created
        )
    }
}
