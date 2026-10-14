import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling goal batch is in its life cycle.
    enum RollingGoalBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rolling goal batch and its current status.
    final class RollingGoalBatch {
        var code: String
        var name: String
        var attributes: [String: String]
        var unit: String
        var title: String
        var amount: Double
        var status: RollingGoalBatchStatus

        init(code: String, name: String, attributes: [String: String], unit: String, title: String, amount: Double, status: RollingGoalBatchStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.unit = unit
            self.title = title
            self.amount = amount
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

        func canMoveTo(_ next: RollingGoalBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingGoalBatchStatus.suspended
            case .pending:
                return next == RollingGoalBatchStatus.active || next == RollingGoalBatchStatus.suspended
            case .active:
                return next == RollingGoalBatchStatus.suspended || next == RollingGoalBatchStatus.closed
            case .suspended:
                return next == RollingGoalBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingGoalBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling goal batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func copyValue() -> RollingGoalBatch {
            return RollingGoalBatch(
                code: code,
                name: name,
                attributes: attributes,
                unit: unit,
                title: title,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling goal batch in status draft.
    static func newRollingGoalBatch(_ code: String, name: String) -> RollingGoalBatch {
        return RollingGoalBatch(
            code: code,
            name: name,
            attributes: [:],
            unit: "",
            title: "",
            amount: 0.0,
            status: RollingGoalBatchStatus.draft
        )
    }
}
