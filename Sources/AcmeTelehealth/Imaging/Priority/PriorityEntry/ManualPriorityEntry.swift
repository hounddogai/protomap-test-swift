import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual priority entry is in its life cycle.
    enum ManualPriorityEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual priority entry. Its code is unique within a tenant.
    final class ManualPriorityEntry {
        var code: String
        var label: String
        var floorValue: Double
        var ceiling: Double
        var priority: Int
        var status: ManualPriorityEntryStatus

        init(code: String, label: String, floorValue: Double, ceiling: Double, priority: Int, status: ManualPriorityEntryStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.ceiling = ceiling
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualPriorityEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualPriorityEntryStatus.resolved
            case .inReview:
                return next == ManualPriorityEntryStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualPriorityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual priority entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ManualPriorityEntry {
            return ManualPriorityEntry(
                code: code,
                label: label,
                floorValue: floorValue,
                ceiling: ceiling,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual priority entry in status open.
    static func newManualPriorityEntry(_ code: String, label: String) -> ManualPriorityEntry {
        return ManualPriorityEntry(
            code: code,
            label: label,
            floorValue: 0.0,
            ceiling: 0.0,
            priority: 0,
            status: ManualPriorityEntryStatus.`open`
        )
    }
}
