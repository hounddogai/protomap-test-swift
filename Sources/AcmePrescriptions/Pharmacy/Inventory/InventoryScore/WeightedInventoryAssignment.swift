import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted inventory assignment is in its life cycle.
    enum WeightedInventoryAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One weighted inventory assignment, with what the planners need to act on it.
    final class WeightedInventoryAssignment {
        var code: String
        var title: String
        var encounterID: String
        var timezone: String
        var visible: Bool
        var sequence: Int
        var region: String
        var capacity: Int
        var pinned: Bool
        var diagnosisCode: String
        var status: WeightedInventoryAssignmentStatus

        init(code: String, title: String, encounterID: String, timezone: String, visible: Bool, sequence: Int, region: String, capacity: Int, pinned: Bool, diagnosisCode: String, status: WeightedInventoryAssignmentStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.timezone = timezone
            self.visible = visible
            self.sequence = sequence
            self.region = region
            self.capacity = capacity
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: WeightedInventoryAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedInventoryAssignmentStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedInventoryAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted inventory assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInventoryAssignment {
            return WeightedInventoryAssignment(
                code: code,
                title: title,
                encounterID: encounterID,
                timezone: timezone,
                visible: visible,
                sequence: sequence,
                region: region,
                capacity: capacity,
                pinned: pinned,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted inventory assignment in status draft.
    static func newWeightedInventoryAssignment(_ code: String, title: String) -> WeightedInventoryAssignment {
        return WeightedInventoryAssignment(
            code: code,
            title: title,
            encounterID: "",
            timezone: "",
            visible: false,
            sequence: 0,
            region: "",
            capacity: 0,
            pinned: false,
            diagnosisCode: "",
            status: WeightedInventoryAssignmentStatus.draft
        )
    }
}
