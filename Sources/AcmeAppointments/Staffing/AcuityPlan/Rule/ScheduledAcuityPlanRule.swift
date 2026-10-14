import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled acuity plan rule is in its life cycle.
    enum ScheduledAcuityPlanRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One scheduled acuity plan rule, with what the planners need to act on it.
    final class ScheduledAcuityPlanRule {
        var code: String
        var label: String
        var attributes: [String: String]
        var phone: String
        var sequence: Int
        var acuity: Int
        var cost: Double
        var ratio: Double
        var contactEmail: String
        var status: ScheduledAcuityPlanRuleStatus

        init(code: String, label: String, attributes: [String: String], phone: String, sequence: Int, acuity: Int, cost: Double, ratio: Double, contactEmail: String, status: ScheduledAcuityPlanRuleStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.phone = phone
            self.sequence = sequence
            self.acuity = acuity
            self.cost = cost
            self.ratio = ratio
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ScheduledAcuityPlanRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledAcuityPlanRuleStatus.reopened
            case .inReview:
                return next == ScheduledAcuityPlanRuleStatus.archived
            case .resolved:
                return next == ScheduledAcuityPlanRuleStatus.reopened
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

        func moveTo(_ next: ScheduledAcuityPlanRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled acuity plan rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled acuity plan rule") \(code)"
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

        func weightedValue() -> Double {
            return ((Double(acuity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAcuityPlanRule {
            return ScheduledAcuityPlanRule(
                code: code,
                label: label,
                attributes: attributes,
                phone: phone,
                sequence: sequence,
                acuity: acuity,
                cost: cost,
                ratio: ratio,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled acuity plan rule in status open.
    static func newScheduledAcuityPlanRule(_ code: String, label: String) -> ScheduledAcuityPlanRule {
        return ScheduledAcuityPlanRule(
            code: code,
            label: label,
            attributes: [:],
            phone: "",
            sequence: 0,
            acuity: 0,
            cost: 0.0,
            ratio: 0.0,
            contactEmail: "",
            status: ScheduledAcuityPlanRuleStatus.`open`
        )
    }
}
