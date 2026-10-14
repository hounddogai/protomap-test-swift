import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task snapshot is in its life cycle.
    enum TaskSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task snapshot. Its code is unique within a tenant.
    final class TaskSnapshot {
        var code: String
        var label: String
        var payer: String
        var summary: String
        var timezone: String
        var amount: Double
        var status: TaskSnapshotStatus

        init(code: String, label: String, payer: String, summary: String, timezone: String, amount: Double, status: TaskSnapshotStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.summary = summary
            self.timezone = timezone
            self.amount = amount
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

        func canMoveTo(_ next: TaskSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TaskSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> TaskSnapshot {
            return TaskSnapshot(
                code: code,
                label: label,
                payer: payer,
                summary: summary,
                timezone: timezone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task snapshot in status new.
    static func newTaskSnapshot(_ code: String, label: String) -> TaskSnapshot {
        return TaskSnapshot(
            code: code,
            label: label,
            payer: "",
            summary: "",
            timezone: "",
            amount: 0.0,
            status: TaskSnapshotStatus.new
        )
    }
}
