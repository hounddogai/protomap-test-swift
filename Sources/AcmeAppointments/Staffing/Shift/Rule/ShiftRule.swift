import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift rule is in its life cycle.
    enum ShiftRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a shift rule and its current status.
    final class ShiftRule {
        var code: String
        var title: String
        var updatedAt: Int
        var visible: Bool
        var floorValue: Double
        var revision: Int
        var sequence: Int
        var ward: String
        var status: ShiftRuleStatus

        init(code: String, title: String, updatedAt: Int, visible: Bool, floorValue: Double, revision: Int, sequence: Int, ward: String, status: ShiftRuleStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.visible = visible
            self.floorValue = floorValue
            self.revision = revision
            self.sequence = sequence
            self.ward = ward
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

        func canMoveTo(_ next: ShiftRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ShiftRuleStatus.suspended
            case .active:
                return next == ShiftRuleStatus.suspended || next == ShiftRuleStatus.closed
            case .suspended:
                return next == ShiftRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(updatedAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftRule {
            return ShiftRule(
                code: code,
                title: title,
                updatedAt: updatedAt,
                visible: visible,
                floorValue: floorValue,
                revision: revision,
                sequence: sequence,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a shift rule in status draft.
    static func newShiftRule(_ code: String, title: String) -> ShiftRule {
        return ShiftRule(
            code: code,
            title: title,
            updatedAt: 0,
            visible: false,
            floorValue: 0.0,
            revision: 0,
            sequence: 0,
            ward: "",
            status: ShiftRuleStatus.draft
        )
    }
}
