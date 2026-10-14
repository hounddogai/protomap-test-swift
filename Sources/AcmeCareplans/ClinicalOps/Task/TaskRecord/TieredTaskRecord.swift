import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task record is in its life cycle.
    enum TieredTaskRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered task record as the task team keeps it.
    final class TieredTaskRecord {
        var code: String
        var label: String
        var timezone: String
        var floorValue: Double
        var description: String
        var ward: String
        var attempts: Int
        var budget: Double
        var durationMinutes: Int
        var ownerID: String
        var status: TieredTaskRecordStatus

        init(code: String, label: String, timezone: String, floorValue: Double, description: String, ward: String, attempts: Int, budget: Double, durationMinutes: Int, ownerID: String, status: TieredTaskRecordStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.floorValue = floorValue
            self.description = description
            self.ward = ward
            self.attempts = attempts
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
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

        func canMoveTo(_ next: TieredTaskRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TieredTaskRecordStatus.cancelled
            case .inProgress:
                return next == TieredTaskRecordStatus.completed || next == TieredTaskRecordStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredTaskRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((budget - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> TieredTaskRecord {
            return TieredTaskRecord(
                code: code,
                label: label,
                timezone: timezone,
                floorValue: floorValue,
                description: description,
                ward: ward,
                attempts: attempts,
                budget: budget,
                durationMinutes: durationMinutes,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered task record in status planned.
    static func newTieredTaskRecord(_ code: String, label: String) -> TieredTaskRecord {
        return TieredTaskRecord(
            code: code,
            label: label,
            timezone: "",
            floorValue: 0.0,
            description: "",
            ward: "",
            attempts: 0,
            budget: 0.0,
            durationMinutes: 0,
            ownerID: "",
            status: TieredTaskRecordStatus.planned
        )
    }
}
