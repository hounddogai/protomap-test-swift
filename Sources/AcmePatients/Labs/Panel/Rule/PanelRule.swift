import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel rule is in its life cycle.
    enum PanelRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A panel rule. Its code is unique within a tenant.
    final class PanelRule {
        var code: String
        var name: String
        var channel: String
        var visible: Bool
        var cost: Double
        var archived: Bool
        var summary: String
        var patientRef: String
        var status: PanelRuleStatus

        init(code: String, name: String, channel: String, visible: Bool, cost: Double, archived: Bool, summary: String, patientRef: String, status: PanelRuleStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.visible = visible
            self.cost = cost
            self.archived = archived
            self.summary = summary
            self.patientRef = patientRef
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

        func canMoveTo(_ next: PanelRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PanelRuleStatus.reopened || next == PanelRuleStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PanelRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel rule") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> PanelRule {
            return PanelRule(
                code: code,
                name: name,
                channel: channel,
                visible: visible,
                cost: cost,
                archived: archived,
                summary: summary,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a panel rule in status open.
    static func newPanelRule(_ code: String, name: String) -> PanelRule {
        return PanelRule(
            code: code,
            name: name,
            channel: "",
            visible: false,
            cost: 0.0,
            archived: false,
            summary: "",
            patientRef: "",
            status: PanelRuleStatus.`open`
        )
    }
}
