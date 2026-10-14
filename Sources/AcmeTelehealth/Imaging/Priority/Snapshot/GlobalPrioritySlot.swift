import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global priority slot is in its life cycle.
    enum GlobalPrioritySlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global priority slot as the priority team keeps it.
    final class GlobalPrioritySlot {
        var code: String
        var label: String
        var encounterID: String
        var summary: String
        var ward: String
        var priority: Int
        var clinicianID: String
        var facility: String
        var unit: String
        var status: GlobalPrioritySlotStatus

        init(code: String, label: String, encounterID: String, summary: String, ward: String, priority: Int, clinicianID: String, facility: String, unit: String, status: GlobalPrioritySlotStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.summary = summary
            self.ward = ward
            self.priority = priority
            self.clinicianID = clinicianID
            self.facility = facility
            self.unit = unit
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

        func canMoveTo(_ next: GlobalPrioritySlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GlobalPrioritySlotStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GlobalPrioritySlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalPrioritySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global priority slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> GlobalPrioritySlot {
            return GlobalPrioritySlot(
                code: code,
                label: label,
                encounterID: encounterID,
                summary: summary,
                ward: ward,
                priority: priority,
                clinicianID: clinicianID,
                facility: facility,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global priority slot in status open.
    static func newGlobalPrioritySlot(_ code: String, label: String) -> GlobalPrioritySlot {
        return GlobalPrioritySlot(
            code: code,
            label: label,
            encounterID: "",
            summary: "",
            ward: "",
            priority: 0,
            clinicianID: "",
            facility: "",
            unit: "",
            status: GlobalPrioritySlotStatus.`open`
        )
    }
}
