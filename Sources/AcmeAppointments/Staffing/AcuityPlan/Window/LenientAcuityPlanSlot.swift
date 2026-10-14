import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan slot is in its life cycle.
    enum LenientAcuityPlanSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient acuity plan slot, with what the planners need to act on it.
    final class LenientAcuityPlanSlot {
        var code: String
        var title: String
        var visible: Bool
        var maximum: Double
        var margin: Double
        var quantity: Int
        var status: LenientAcuityPlanSlotStatus

        init(code: String, title: String, visible: Bool, maximum: Double, margin: Double, quantity: Int, status: LenientAcuityPlanSlotStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.maximum = maximum
            self.margin = margin
            self.quantity = quantity
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

        func canMoveTo(_ next: LenientAcuityPlanSlotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientAcuityPlanSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return (margin * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanSlot {
            return LenientAcuityPlanSlot(
                code: code,
                title: title,
                visible: visible,
                maximum: maximum,
                margin: margin,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient acuity plan slot in status draft.
    static func newLenientAcuityPlanSlot(_ code: String, title: String) -> LenientAcuityPlanSlot {
        return LenientAcuityPlanSlot(
            code: code,
            title: title,
            visible: false,
            maximum: 0.0,
            margin: 0.0,
            quantity: 0,
            status: LenientAcuityPlanSlotStatus.draft
        )
    }
}
