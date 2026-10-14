import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation rule is in its life cycle.
    enum RevocationRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a revocation rule and its current status.
    final class RevocationRule {
        var code: String
        var name: String
        var revision: Int
        var allergy: String
        var amount: Double
        var status: RevocationRuleStatus

        init(code: String, name: String, revision: Int, allergy: String, amount: Double, status: RevocationRuleStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.allergy = allergy
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == RevocationRuleStatus.pending || next == RevocationRuleStatus.suspended
            case .pending:
                return next == RevocationRuleStatus.suspended || next == RevocationRuleStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RevocationRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((amount + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationRule {
            return RevocationRule(
                code: code,
                name: name,
                revision: revision,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a revocation rule in status draft.
    static func newRevocationRule(_ code: String, name: String) -> RevocationRule {
        return RevocationRule(
            code: code,
            name: name,
            revision: 0,
            allergy: "",
            amount: 0.0,
            status: RevocationRuleStatus.draft
        )
    }
}
