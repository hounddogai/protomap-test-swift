import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict reference range rule is in its life cycle.
    enum StrictReferenceRangeRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict reference range rule. Its code is unique within a tenant.
    final class StrictReferenceRangeRule {
        var code: String
        var name: String
        var endsAt: Int
        var label: String
        var version: Int
        var quantity: Int
        var status: StrictReferenceRangeRuleStatus

        init(code: String, name: String, endsAt: Int, label: String, version: Int, quantity: Int, status: StrictReferenceRangeRuleStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.label = label
            self.version = version
            self.quantity = quantity
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

        func canMoveTo(_ next: StrictReferenceRangeRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictReferenceRangeRuleStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StrictReferenceRangeRuleStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: StrictReferenceRangeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict reference range rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((Double(version) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferenceRangeRule {
            return StrictReferenceRangeRule(
                code: code,
                name: name,
                endsAt: endsAt,
                label: label,
                version: version,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict reference range rule in status open.
    static func newStrictReferenceRangeRule(_ code: String, name: String) -> StrictReferenceRangeRule {
        return StrictReferenceRangeRule(
            code: code,
            name: name,
            endsAt: 0,
            label: "",
            version: 0,
            quantity: 0,
            status: StrictReferenceRangeRuleStatus.`open`
        )
    }
}
