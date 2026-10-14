import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional panel rule is in its life cycle.
    enum RegionalPanelRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One regional panel rule, with what the planners need to act on it.
    final class RegionalPanelRule {
        var code: String
        var title: String
        var ceiling: Double
        var diagnosisCode: String
        var minimum: Double
        var facility: String
        var limit: Int
        var archived: Bool
        var status: RegionalPanelRuleStatus

        init(code: String, title: String, ceiling: Double, diagnosisCode: String, minimum: Double, facility: String, limit: Int, archived: Bool, status: RegionalPanelRuleStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.facility = facility
            self.limit = limit
            self.archived = archived
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

        func canMoveTo(_ next: RegionalPanelRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalPanelRuleStatus.pending || next == RegionalPanelRuleStatus.active
            case .pending:
                return next == RegionalPanelRuleStatus.suspended
            case .active:
                return next == RegionalPanelRuleStatus.suspended
            case .suspended:
                return next == RegionalPanelRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalPanelRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional panel rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(limit) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> RegionalPanelRule {
            return RegionalPanelRule(
                code: code,
                title: title,
                ceiling: ceiling,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                facility: facility,
                limit: limit,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional panel rule in status draft.
    static func newRegionalPanelRule(_ code: String, title: String) -> RegionalPanelRule {
        return RegionalPanelRule(
            code: code,
            title: title,
            ceiling: 0.0,
            diagnosisCode: "",
            minimum: 0.0,
            facility: "",
            limit: 0,
            archived: false,
            status: RegionalPanelRuleStatus.draft
        )
    }
}
