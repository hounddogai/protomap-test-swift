import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime target is in its life cycle.
    enum OvertimeTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a overtime target and its current status.
    final class OvertimeTarget {
        var code: String
        var label: String
        var limit: Int
        var title: String
        var ceiling: Double
        var summary: String
        var floorValue: Double
        var externalRef: String
        var unit: String
        var approved: Bool
        var minimum: Double
        var status: OvertimeTargetStatus

        init(code: String, label: String, limit: Int, title: String, ceiling: Double, summary: String, floorValue: Double, externalRef: String, unit: String, approved: Bool, minimum: Double, status: OvertimeTargetStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.title = title
            self.ceiling = ceiling
            self.summary = summary
            self.floorValue = floorValue
            self.externalRef = externalRef
            self.unit = unit
            self.approved = approved
            self.minimum = minimum
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

        func canMoveTo(_ next: OvertimeTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == OvertimeTargetStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OvertimeTargetStatus.suspended || next == OvertimeTargetStatus.closed
            case .suspended:
                return next == OvertimeTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return (ceiling * floorValue * 100).rounded() / 100
        }

        func copyValue() -> OvertimeTarget {
            return OvertimeTarget(
                code: code,
                label: label,
                limit: limit,
                title: title,
                ceiling: ceiling,
                summary: summary,
                floorValue: floorValue,
                externalRef: externalRef,
                unit: unit,
                approved: approved,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a overtime target in status draft.
    static func newOvertimeTarget(_ code: String, label: String) -> OvertimeTarget {
        return OvertimeTarget(
            code: code,
            label: label,
            limit: 0,
            title: "",
            ceiling: 0.0,
            summary: "",
            floorValue: 0.0,
            externalRef: "",
            unit: "",
            approved: false,
            minimum: 0.0,
            status: OvertimeTargetStatus.draft
        )
    }
}
