import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement adjustment is in its life cycle.
    enum StatementAdjustmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A statement adjustment as the statement team keeps it.
    final class StatementAdjustment {
        var code: String
        var label: String
        var ceiling: Double
        var category: String
        var encounterID: String
        var priority: Int
        var dosageMg: Double
        var visitMinutes: Int
        var channel: String
        var status: StatementAdjustmentStatus

        init(code: String, label: String, ceiling: Double, category: String, encounterID: String, priority: Int, dosageMg: Double, visitMinutes: Int, channel: String, status: StatementAdjustmentStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.category = category
            self.encounterID = encounterID
            self.priority = priority
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.channel = channel
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

        func canMoveTo(_ next: StatementAdjustmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StatementAdjustmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return ((Double(priority) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StatementAdjustment {
            return StatementAdjustment(
                code: code,
                label: label,
                ceiling: ceiling,
                category: category,
                encounterID: encounterID,
                priority: priority,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a statement adjustment in status proposed.
    static func newStatementAdjustment(_ code: String, label: String) -> StatementAdjustment {
        return StatementAdjustment(
            code: code,
            label: label,
            ceiling: 0.0,
            category: "",
            encounterID: "",
            priority: 0,
            dosageMg: 0.0,
            visitMinutes: 0,
            channel: "",
            status: StatementAdjustmentStatus.proposed
        )
    }
}
