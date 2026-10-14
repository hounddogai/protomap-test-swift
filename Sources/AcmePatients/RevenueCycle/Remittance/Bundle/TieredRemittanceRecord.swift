import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance record is in its life cycle.
    enum TieredRemittanceRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered remittance record as the remittance team keeps it.
    final class TieredRemittanceRecord {
        var code: String
        var name: String
        var updatedAt: Int
        var floorValue: Double
        var ceiling: Double
        var attempts: Int
        var margin: Double
        var status: TieredRemittanceRecordStatus

        init(code: String, name: String, updatedAt: Int, floorValue: Double, ceiling: Double, attempts: Int, margin: Double, status: TieredRemittanceRecordStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.floorValue = floorValue
            self.ceiling = ceiling
            self.attempts = attempts
            self.margin = margin
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

        func canMoveTo(_ next: TieredRemittanceRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredRemittanceRecordStatus.scheduled || next == TieredRemittanceRecordStatus.completed
            case .scheduled:
                return next == TieredRemittanceRecordStatus.completed
            case .inProgress:
                return next == TieredRemittanceRecordStatus.cancelled
            case .completed:
                return next == TieredRemittanceRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRemittanceRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (floorValue * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceRecord {
            return TieredRemittanceRecord(
                code: code,
                name: name,
                updatedAt: updatedAt,
                floorValue: floorValue,
                ceiling: ceiling,
                attempts: attempts,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered remittance record in status planned.
    static func newTieredRemittanceRecord(_ code: String, name: String) -> TieredRemittanceRecord {
        return TieredRemittanceRecord(
            code: code,
            name: name,
            updatedAt: 0,
            floorValue: 0.0,
            ceiling: 0.0,
            attempts: 0,
            margin: 0.0,
            status: TieredRemittanceRecordStatus.planned
        )
    }
}
