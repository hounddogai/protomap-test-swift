import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result rule is in its life cycle.
    enum PendingResultRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending result rule as the result team keeps it.
    final class PendingResultRule {
        var code: String
        var name: String
        var procedureCode: String
        var active: Bool
        var ratio: Double
        var attributes: [String: String]
        var retries: Int
        var status: PendingResultRuleStatus

        init(code: String, name: String, procedureCode: String, active: Bool, ratio: Double, attributes: [String: String], retries: Int, status: PendingResultRuleStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.active = active
            self.ratio = ratio
            self.attributes = attributes
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingResultRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingResultRuleStatus.inReview
            case .inReview:
                return next == PendingResultRuleStatus.reopened
            case .resolved:
                return next == PendingResultRuleStatus.archived
            case .reopened:
                return next == PendingResultRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingResultRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((ratio + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingResultRule {
            return PendingResultRule(
                code: code,
                name: name,
                procedureCode: procedureCode,
                active: active,
                ratio: ratio,
                attributes: attributes,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending result rule in status open.
    static func newPendingResultRule(_ code: String, name: String) -> PendingResultRule {
        return PendingResultRule(
            code: code,
            name: name,
            procedureCode: "",
            active: false,
            ratio: 0.0,
            attributes: [:],
            retries: 0,
            status: PendingResultRuleStatus.`open`
        )
    }
}
