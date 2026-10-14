import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer rule is in its life cycle.
    enum TransferRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One transfer rule, with what the planners need to act on it.
    final class TransferRule {
        var code: String
        var label: String
        var limit: Int
        var visitMinutes: Int
        var cost: Double
        var status: TransferRuleStatus

        init(code: String, label: String, limit: Int, visitMinutes: Int, cost: Double, status: TransferRuleStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.cost = cost
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

        func canMoveTo(_ next: TransferRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == TransferRuleStatus.pending
            case .pending:
                return next == TransferRuleStatus.suspended || next == TransferRuleStatus.closed
            case .active:
                return next == TransferRuleStatus.suspended || next == TransferRuleStatus.closed
            case .suspended:
                return next == TransferRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(visitMinutes) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TransferRule {
            return TransferRule(
                code: code,
                label: label,
                limit: limit,
                visitMinutes: visitMinutes,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer rule in status draft.
    static func newTransferRule(_ code: String, label: String) -> TransferRule {
        return TransferRule(
            code: code,
            label: label,
            limit: 0,
            visitMinutes: 0,
            cost: 0.0,
            status: TransferRuleStatus.draft
        )
    }
}
