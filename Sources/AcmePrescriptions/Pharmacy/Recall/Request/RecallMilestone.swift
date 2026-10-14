import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall milestone is in its life cycle.
    enum RecallMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A recall milestone as the recall team keeps it.
    final class RecallMilestone {
        var code: String
        var label: String
        var bed: String
        var version: Int
        var country: String
        var status: RecallMilestoneStatus

        init(code: String, label: String, bed: String, version: Int, country: String, status: RecallMilestoneStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.version = version
            self.country = country
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

        func canMoveTo(_ next: RecallMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RecallMilestoneStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RecallMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> RecallMilestone {
            return RecallMilestone(
                code: code,
                label: label,
                bed: bed,
                version: version,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a recall milestone in status planned.
    static func newRecallMilestone(_ code: String, label: String) -> RecallMilestone {
        return RecallMilestone(
            code: code,
            label: label,
            bed: "",
            version: 0,
            country: "",
            status: RecallMilestoneStatus.planned
        )
    }
}
