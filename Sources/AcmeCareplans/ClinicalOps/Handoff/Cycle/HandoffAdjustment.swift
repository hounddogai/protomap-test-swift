import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff adjustment is in its life cycle.
    enum HandoffAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A handoff adjustment as the handoff team keeps it.
    final class HandoffAdjustment {
        var code: String
        var title: String
        var ward: String
        var summary: String
        var timezone: String
        var diagnosisCode: String
        var quantity: Int
        var status: HandoffAdjustmentStatus

        init(code: String, title: String, ward: String, summary: String, timezone: String, diagnosisCode: String, quantity: Int, status: HandoffAdjustmentStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.summary = summary
            self.timezone = timezone
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: HandoffAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == HandoffAdjustmentStatus.active || next == HandoffAdjustmentStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == HandoffAdjustmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> HandoffAdjustment {
            return HandoffAdjustment(
                code: code,
                title: title,
                ward: ward,
                summary: summary,
                timezone: timezone,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a handoff adjustment in status draft.
    static func newHandoffAdjustment(_ code: String, title: String) -> HandoffAdjustment {
        return HandoffAdjustment(
            code: code,
            title: title,
            ward: "",
            summary: "",
            timezone: "",
            diagnosisCode: "",
            quantity: 0,
            status: HandoffAdjustmentStatus.draft
        )
    }
}
