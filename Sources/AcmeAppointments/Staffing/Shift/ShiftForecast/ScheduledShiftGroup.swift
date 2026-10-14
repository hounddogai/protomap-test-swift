import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled shift group is in its life cycle.
    enum ScheduledShiftGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One scheduled shift group, with what the planners need to act on it.
    final class ScheduledShiftGroup {
        var code: String
        var label: String
        var pinned: Bool
        var batchSize: Int
        var durationMinutes: Int
        var copay: Double
        var payer: String
        var status: ScheduledShiftGroupStatus

        init(code: String, label: String, pinned: Bool, batchSize: Int, durationMinutes: Int, copay: Double, payer: String, status: ScheduledShiftGroupStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.batchSize = batchSize
            self.durationMinutes = durationMinutes
            self.copay = copay
            self.payer = payer
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

        func canMoveTo(_ next: ScheduledShiftGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledShiftGroupStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledShiftGroupStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ScheduledShiftGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled shift group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("scheduled shift group") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(batchSize) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledShiftGroup {
            return ScheduledShiftGroup(
                code: code,
                label: label,
                pinned: pinned,
                batchSize: batchSize,
                durationMinutes: durationMinutes,
                copay: copay,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled shift group in status draft.
    static func newScheduledShiftGroup(_ code: String, label: String) -> ScheduledShiftGroup {
        return ScheduledShiftGroup(
            code: code,
            label: label,
            pinned: false,
            batchSize: 0,
            durationMinutes: 0,
            copay: 0.0,
            payer: "",
            status: ScheduledShiftGroupStatus.draft
        )
    }
}
