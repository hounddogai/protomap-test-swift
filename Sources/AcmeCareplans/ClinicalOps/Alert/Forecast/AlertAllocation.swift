import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert allocation is in its life cycle.
    enum AlertAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A alert allocation. Its code is unique within a tenant.
    final class AlertAllocation {
        var code: String
        var label: String
        var encounterID: String
        var reviewer: String
        var priority: Int
        var status: AlertAllocationStatus

        init(code: String, label: String, encounterID: String, reviewer: String, priority: Int, status: AlertAllocationStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.priority = priority
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

        func canMoveTo(_ next: AlertAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AlertAllocationStatus.done || next == AlertAllocationStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AlertAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("alert allocation") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> AlertAllocation {
            return AlertAllocation(
                code: code,
                label: label,
                encounterID: encounterID,
                reviewer: reviewer,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert allocation in status new.
    static func newAlertAllocation(_ code: String, label: String) -> AlertAllocation {
        return AlertAllocation(
            code: code,
            label: label,
            encounterID: "",
            reviewer: "",
            priority: 0,
            status: AlertAllocationStatus.new
        )
    }
}
