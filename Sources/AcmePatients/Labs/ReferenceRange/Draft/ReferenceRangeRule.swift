import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range rule is in its life cycle.
    enum ReferenceRangeRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A reference range rule as the reference range team keeps it.
    final class ReferenceRangeRule {
        var code: String
        var label: String
        var dosageMg: Double
        var score: Double
        var graceDays: Int
        var country: String
        var patientRef: String
        var status: ReferenceRangeRuleStatus

        init(code: String, label: String, dosageMg: Double, score: Double, graceDays: Int, country: String, patientRef: String, status: ReferenceRangeRuleStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.score = score
            self.graceDays = graceDays
            self.country = country
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReferenceRangeRuleStatus.revoked
            case .granted:
                return next == ReferenceRangeRuleStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ReferenceRangeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveValue() -> Double {
            return (score * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeRule {
            return ReferenceRangeRule(
                code: code,
                label: label,
                dosageMg: dosageMg,
                score: score,
                graceDays: graceDays,
                country: country,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a reference range rule in status requested.
    static func newReferenceRangeRule(_ code: String, label: String) -> ReferenceRangeRule {
        return ReferenceRangeRule(
            code: code,
            label: label,
            dosageMg: 0.0,
            score: 0.0,
            graceDays: 0,
            country: "",
            patientRef: "",
            status: ReferenceRangeRuleStatus.requested
        )
    }
}
