import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual skill mix milestone is in its life cycle.
    enum ManualSkillMixMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual skill mix milestone as the skill mix team keeps it.
    final class ManualSkillMixMilestone {
        var code: String
        var label: String
        var amount: Double
        var phone: String
        var attributes: [String: String]
        var reviewer: String
        var title: String
        var status: ManualSkillMixMilestoneStatus

        init(code: String, label: String, amount: Double, phone: String, attributes: [String: String], reviewer: String, title: String, status: ManualSkillMixMilestoneStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.phone = phone
            self.attributes = attributes
            self.reviewer = reviewer
            self.title = title
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

        func canMoveTo(_ next: ManualSkillMixMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualSkillMixMilestoneStatus.validated || next == ManualSkillMixMilestoneStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ManualSkillMixMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSkillMixMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual skill mix milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return amount
        }

        func copyValue() -> ManualSkillMixMilestone {
            return ManualSkillMixMilestone(
                code: code,
                label: label,
                amount: amount,
                phone: phone,
                attributes: attributes,
                reviewer: reviewer,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual skill mix milestone in status created.
    static func newManualSkillMixMilestone(_ code: String, label: String) -> ManualSkillMixMilestone {
        return ManualSkillMixMilestone(
            code: code,
            label: label,
            amount: 0.0,
            phone: "",
            attributes: [:],
            reviewer: "",
            title: "",
            status: ManualSkillMixMilestoneStatus.created
        )
    }
}
