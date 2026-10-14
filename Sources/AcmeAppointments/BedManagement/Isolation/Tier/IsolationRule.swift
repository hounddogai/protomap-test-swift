import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation rule is in its life cycle.
    enum IsolationRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One isolation rule, with what the planners need to act on it.
    final class IsolationRule {
        var code: String
        var title: String
        var externalRef: String
        var acuity: Int
        var notes: String
        var graceDays: Int
        var attributes: [String: String]
        var retries: Int
        var active: Bool
        var status: IsolationRuleStatus

        init(code: String, title: String, externalRef: String, acuity: Int, notes: String, graceDays: Int, attributes: [String: String], retries: Int, active: Bool, status: IsolationRuleStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.acuity = acuity
            self.notes = notes
            self.graceDays = graceDays
            self.attributes = attributes
            self.retries = retries
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == IsolationRuleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: IsolationRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveValue() -> Double {
            return ((Double(retries) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationRule {
            return IsolationRule(
                code: code,
                title: title,
                externalRef: externalRef,
                acuity: acuity,
                notes: notes,
                graceDays: graceDays,
                attributes: attributes,
                retries: retries,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation rule in status proposed.
    static func newIsolationRule(_ code: String, title: String) -> IsolationRule {
        return IsolationRule(
            code: code,
            title: title,
            externalRef: "",
            acuity: 0,
            notes: "",
            graceDays: 0,
            attributes: [:],
            retries: 0,
            active: false,
            status: IsolationRuleStatus.proposed
        )
    }
}
