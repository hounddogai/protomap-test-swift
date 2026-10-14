import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program bundle is in its life cycle.
    enum ProgramBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a program bundle and its current status.
    final class ProgramBundle {
        var code: String
        var label: String
        var visible: Bool
        var currency: String
        var reviewer: String
        var amount: Double
        var status: ProgramBundleStatus

        init(code: String, label: String, visible: Bool, currency: String, reviewer: String, amount: Double, status: ProgramBundleStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.currency = currency
            self.reviewer = reviewer
            self.amount = amount
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

        func canMoveTo(_ next: ProgramBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == ProgramBundleStatus.inProgress || next == ProgramBundleStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ProgramBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ProgramBundle {
            return ProgramBundle(
                code: code,
                label: label,
                visible: visible,
                currency: currency,
                reviewer: reviewer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a program bundle in status planned.
    static func newProgramBundle(_ code: String, label: String) -> ProgramBundle {
        return ProgramBundle(
            code: code,
            label: label,
            visible: false,
            currency: "",
            reviewer: "",
            amount: 0.0,
            status: ProgramBundleStatus.planned
        )
    }
}
