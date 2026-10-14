import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession rule is in its life cycle.
    enum AccessionRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a accession rule and its current status.
    final class AccessionRule {
        var code: String
        var name: String
        var description: String
        var visible: Bool
        var durationMinutes: Int
        var ward: String
        var attempts: Int
        var budget: Double
        var copay: Double
        var archived: Bool
        var status: AccessionRuleStatus

        init(code: String, name: String, description: String, visible: Bool, durationMinutes: Int, ward: String, attempts: Int, budget: Double, copay: Double, archived: Bool, status: AccessionRuleStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.attempts = attempts
            self.budget = budget
            self.copay = copay
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == AccessionRuleStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AccessionRuleStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AccessionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("accession rule") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) + budget) * 100).rounded() / 100
        }

        func copyValue() -> AccessionRule {
            return AccessionRule(
                code: code,
                name: name,
                description: description,
                visible: visible,
                durationMinutes: durationMinutes,
                ward: ward,
                attempts: attempts,
                budget: budget,
                copay: copay,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a accession rule in status idle.
    static func newAccessionRule(_ code: String, name: String) -> AccessionRule {
        return AccessionRule(
            code: code,
            name: name,
            description: "",
            visible: false,
            durationMinutes: 0,
            ward: "",
            attempts: 0,
            budget: 0.0,
            copay: 0.0,
            archived: false,
            status: AccessionRuleStatus.idle
        )
    }
}
