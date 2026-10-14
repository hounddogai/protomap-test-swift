import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional overtime window is in its life cycle.
    enum RegionalOvertimeWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional overtime window as the overtime team keeps it.
    final class RegionalOvertimeWindow {
        var code: String
        var name: String
        var active: Bool
        var durationMinutes: Int
        var batchSize: Int
        var ward: String
        var score: Double
        var procedureCode: String
        var status: RegionalOvertimeWindowStatus

        init(code: String, name: String, active: Bool, durationMinutes: Int, batchSize: Int, ward: String, score: Double, procedureCode: String, status: RegionalOvertimeWindowStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.ward = ward
            self.score = score
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RegionalOvertimeWindowStatus) -> Bool {
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
                return next == RegionalOvertimeWindowStatus.inProgress || next == RegionalOvertimeWindowStatus.cancelled
            case .inProgress:
                return next == RegionalOvertimeWindowStatus.cancelled
            case .completed:
                return next == RegionalOvertimeWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOvertimeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional overtime window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return (Double(batchSize) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOvertimeWindow {
            return RegionalOvertimeWindow(
                code: code,
                name: name,
                active: active,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                ward: ward,
                score: score,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional overtime window in status planned.
    static func newRegionalOvertimeWindow(_ code: String, name: String) -> RegionalOvertimeWindow {
        return RegionalOvertimeWindow(
            code: code,
            name: name,
            active: false,
            durationMinutes: 0,
            batchSize: 0,
            ward: "",
            score: 0.0,
            procedureCode: "",
            status: RegionalOvertimeWindowStatus.planned
        )
    }
}
