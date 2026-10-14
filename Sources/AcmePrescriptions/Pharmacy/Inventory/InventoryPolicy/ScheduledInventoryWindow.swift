import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory window is in its life cycle.
    enum ScheduledInventoryWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled inventory window. Its code is unique within a tenant.
    final class ScheduledInventoryWindow {
        var code: String
        var label: String
        var cost: Double
        var segment: String
        var diagnosisCode: String
        var bed: String
        var status: ScheduledInventoryWindowStatus

        init(code: String, label: String, cost: Double, segment: String, diagnosisCode: String, bed: String, status: ScheduledInventoryWindowStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.segment = segment
            self.diagnosisCode = diagnosisCode
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledInventoryWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledInventoryWindowStatus.done || next == ScheduledInventoryWindowStatus.failed
            case .queued:
                return next == ScheduledInventoryWindowStatus.running || next == ScheduledInventoryWindowStatus.failed
            case .running:
                return next == ScheduledInventoryWindowStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledInventoryWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> ScheduledInventoryWindow {
            return ScheduledInventoryWindow(
                code: code,
                label: label,
                cost: cost,
                segment: segment,
                diagnosisCode: diagnosisCode,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled inventory window in status new.
    static func newScheduledInventoryWindow(_ code: String, label: String) -> ScheduledInventoryWindow {
        return ScheduledInventoryWindow(
            code: code,
            label: label,
            cost: 0.0,
            segment: "",
            diagnosisCode: "",
            bed: "",
            status: ScheduledInventoryWindowStatus.new
        )
    }
}
