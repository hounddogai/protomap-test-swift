import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime slot is in its life cycle.
    enum OvertimeSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a overtime slot and its current status.
    final class OvertimeSlot {
        var code: String
        var name: String
        var summary: String
        var bed: String
        var visible: Bool
        var label: String
        var score: Double
        var status: OvertimeSlotStatus

        init(code: String, name: String, summary: String, bed: String, visible: Bool, label: String, score: Double, status: OvertimeSlotStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.bed = bed
            self.visible = visible
            self.label = label
            self.score = score
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

        func canMoveTo(_ next: OvertimeSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == OvertimeSlotStatus.active || next == OvertimeSlotStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == OvertimeSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("overtime slot") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> OvertimeSlot {
            return OvertimeSlot(
                code: code,
                name: name,
                summary: summary,
                bed: bed,
                visible: visible,
                label: label,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a overtime slot in status draft.
    static func newOvertimeSlot(_ code: String, name: String) -> OvertimeSlot {
        return OvertimeSlot(
            code: code,
            name: name,
            summary: "",
            bed: "",
            visible: false,
            label: "",
            score: 0.0,
            status: OvertimeSlotStatus.draft
        )
    }
}
