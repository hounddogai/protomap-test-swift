import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution rule is in its life cycle.
    enum SubstitutionRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One substitution rule, with what the planners need to act on it.
    final class SubstitutionRule {
        var code: String
        var title: String
        var active: Bool
        var margin: Double
        var notes: String
        var description: String
        var score: Double
        var status: SubstitutionRuleStatus

        init(code: String, title: String, active: Bool, margin: Double, notes: String, description: String, score: Double, status: SubstitutionRuleStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.margin = margin
            self.notes = notes
            self.description = description
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

        func canMoveTo(_ next: SubstitutionRuleStatus) -> Bool {
            switch status {
            case .created:
                return next == SubstitutionRuleStatus.validated
            case .validated:
                return next == SubstitutionRuleStatus.retired
            case .published:
                return next == SubstitutionRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((margin - score) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionRule {
            return SubstitutionRule(
                code: code,
                title: title,
                active: active,
                margin: margin,
                notes: notes,
                description: description,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution rule in status created.
    static func newSubstitutionRule(_ code: String, title: String) -> SubstitutionRule {
        return SubstitutionRule(
            code: code,
            title: title,
            active: false,
            margin: 0.0,
            notes: "",
            description: "",
            score: 0.0,
            status: SubstitutionRuleStatus.created
        )
    }
}
