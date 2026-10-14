import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal policy is in its life cycle.
    enum GoalPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A goal policy as the goal team keeps it.
    final class GoalPolicy {
        var code: String
        var label: String
        var country: String
        var floorValue: Double
        var reviewer: String
        var currency: String
        var notes: String
        var ownerID: String
        var attributes: [String: String]
        var status: GoalPolicyStatus

        init(code: String, label: String, country: String, floorValue: Double, reviewer: String, currency: String, notes: String, ownerID: String, attributes: [String: String], status: GoalPolicyStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.floorValue = floorValue
            self.reviewer = reviewer
            self.currency = currency
            self.notes = notes
            self.ownerID = ownerID
            self.attributes = attributes
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

        func canMoveTo(_ next: GoalPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GoalPolicyStatus.suspended
            case .suspended:
                return next == GoalPolicyStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> GoalPolicy {
            return GoalPolicy(
                code: code,
                label: label,
                country: country,
                floorValue: floorValue,
                reviewer: reviewer,
                currency: currency,
                notes: notes,
                ownerID: ownerID,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a goal policy in status draft.
    static func newGoalPolicy(_ code: String, label: String) -> GoalPolicy {
        return GoalPolicy(
            code: code,
            label: label,
            country: "",
            floorValue: 0.0,
            reviewer: "",
            currency: "",
            notes: "",
            ownerID: "",
            attributes: [:],
            status: GoalPolicyStatus.draft
        )
    }
}
