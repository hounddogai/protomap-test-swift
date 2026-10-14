import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy task record is in its life cycle.
    enum LegacyTaskRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One legacy task record, with what the planners need to act on it.
    final class LegacyTaskRecord {
        var code: String
        var label: String
        var visible: Bool
        var refills: Int
        var cost: Double
        var currency: String
        var attempts: Int
        var createdAt: Int
        var status: LegacyTaskRecordStatus

        init(code: String, label: String, visible: Bool, refills: Int, cost: Double, currency: String, attempts: Int, createdAt: Int, status: LegacyTaskRecordStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.refills = refills
            self.cost = cost
            self.currency = currency
            self.attempts = attempts
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyTaskRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyTaskRecordStatus.completed || next == LegacyTaskRecordStatus.cancelled
            case .scheduled:
                return next == LegacyTaskRecordStatus.cancelled
            case .inProgress:
                return next == LegacyTaskRecordStatus.completed
            case .completed:
                return next == LegacyTaskRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyTaskRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy task record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return (cost * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> LegacyTaskRecord {
            return LegacyTaskRecord(
                code: code,
                label: label,
                visible: visible,
                refills: refills,
                cost: cost,
                currency: currency,
                attempts: attempts,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy task record in status planned.
    static func newLegacyTaskRecord(_ code: String, label: String) -> LegacyTaskRecord {
        return LegacyTaskRecord(
            code: code,
            label: label,
            visible: false,
            refills: 0,
            cost: 0.0,
            currency: "",
            attempts: 0,
            createdAt: 0,
            status: LegacyTaskRecordStatus.planned
        )
    }
}
