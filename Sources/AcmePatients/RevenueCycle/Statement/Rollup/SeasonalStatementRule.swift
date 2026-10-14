import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal statement rule is in its life cycle.
    enum SeasonalStatementRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One seasonal statement rule, with what the planners need to act on it.
    final class SeasonalStatementRule {
        var code: String
        var title: String
        var reviewer: String
        var capacity: Int
        var encounterID: String
        var payer: String
        var windowDays: Int
        var sequence: Int
        var status: SeasonalStatementRuleStatus

        init(code: String, title: String, reviewer: String, capacity: Int, encounterID: String, payer: String, windowDays: Int, sequence: Int, status: SeasonalStatementRuleStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.capacity = capacity
            self.encounterID = encounterID
            self.payer = payer
            self.windowDays = windowDays
            self.sequence = sequence
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

        func canMoveTo(_ next: SeasonalStatementRuleStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalStatementRuleStatus.validated || next == SeasonalStatementRuleStatus.retired
            case .validated:
                return next == SeasonalStatementRuleStatus.retired
            case .published:
                return next == SeasonalStatementRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalStatementRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal statement rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal statement rule") \(code)"
        }

        func netTotal() -> Double {
            return (Double(capacity) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStatementRule {
            return SeasonalStatementRule(
                code: code,
                title: title,
                reviewer: reviewer,
                capacity: capacity,
                encounterID: encounterID,
                payer: payer,
                windowDays: windowDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal statement rule in status created.
    static func newSeasonalStatementRule(_ code: String, title: String) -> SeasonalStatementRule {
        return SeasonalStatementRule(
            code: code,
            title: title,
            reviewer: "",
            capacity: 0,
            encounterID: "",
            payer: "",
            windowDays: 0,
            sequence: 0,
            status: SeasonalStatementRuleStatus.created
        )
    }
}
