import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation slot is in its life cycle.
    enum IsolationSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A isolation slot. Its code is unique within a tenant.
    final class IsolationSlot {
        var code: String
        var label: String
        var notes: String
        var maximum: Double
        var approved: Bool
        var status: IsolationSlotStatus

        init(code: String, label: String, notes: String, maximum: Double, approved: Bool, status: IsolationSlotStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.maximum = maximum
            self.approved = approved
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

        func canMoveTo(_ next: IsolationSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == IsolationSlotStatus.done || next == IsolationSlotStatus.failed
            case .running:
                return next == IsolationSlotStatus.failed
            case .done:
                return next == IsolationSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> IsolationSlot {
            return IsolationSlot(
                code: code,
                label: label,
                notes: notes,
                maximum: maximum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation slot in status new.
    static func newIsolationSlot(_ code: String, label: String) -> IsolationSlot {
        return IsolationSlot(
            code: code,
            label: label,
            notes: "",
            maximum: 0.0,
            approved: false,
            status: IsolationSlotStatus.new
        )
    }
}
