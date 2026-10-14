import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program adjustment is in its life cycle.
    enum ProgramAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program adjustment, with what the planners need to act on it.
    final class ProgramAdjustment {
        var code: String
        var label: String
        var category: String
        var pinned: Bool
        var acuity: Int
        var status: ProgramAdjustmentStatus

        init(code: String, label: String, category: String, pinned: Bool, acuity: Int, status: ProgramAdjustmentStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.pinned = pinned
            self.acuity = acuity
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

        func canMoveTo(_ next: ProgramAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ProgramAdjustmentStatus.suspended || next == ProgramAdjustmentStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: ProgramAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("program adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> ProgramAdjustment {
            return ProgramAdjustment(
                code: code,
                label: label,
                category: category,
                pinned: pinned,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a program adjustment in status draft.
    static func newProgramAdjustment(_ code: String, label: String) -> ProgramAdjustment {
        return ProgramAdjustment(
            code: code,
            label: label,
            category: "",
            pinned: false,
            acuity: 0,
            status: ProgramAdjustmentStatus.draft
        )
    }
}
