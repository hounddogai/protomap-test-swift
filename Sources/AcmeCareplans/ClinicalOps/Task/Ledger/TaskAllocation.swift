import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task allocation is in its life cycle.
    enum TaskAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A task allocation. Its code is unique within a tenant.
    final class TaskAllocation {
        var code: String
        var label: String
        var locale: String
        var encounterID: String
        var ratio: Double
        var tags: [String]
        var phone: String
        var status: TaskAllocationStatus

        init(code: String, label: String, locale: String, encounterID: String, ratio: Double, tags: [String], phone: String, status: TaskAllocationStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.encounterID = encounterID
            self.ratio = ratio
            self.tags = tags
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TaskAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> TaskAllocation {
            return TaskAllocation(
                code: code,
                label: label,
                locale: locale,
                encounterID: encounterID,
                ratio: ratio,
                tags: tags,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a task allocation in status proposed.
    static func newTaskAllocation(_ code: String, label: String) -> TaskAllocation {
        return TaskAllocation(
            code: code,
            label: label,
            locale: "",
            encounterID: "",
            ratio: 0.0,
            tags: [],
            phone: "",
            status: TaskAllocationStatus.proposed
        )
    }
}
