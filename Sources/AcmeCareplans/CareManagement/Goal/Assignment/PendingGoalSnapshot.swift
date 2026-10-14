import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending goal snapshot is in its life cycle.
    enum PendingGoalSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending goal snapshot as the goal team keeps it.
    final class PendingGoalSnapshot {
        var code: String
        var name: String
        var category: String
        var encounterID: String
        var summary: String
        var approved: Bool
        var maximum: Double
        var ward: String
        var phone: String
        var status: PendingGoalSnapshotStatus

        init(code: String, name: String, category: String, encounterID: String, summary: String, approved: Bool, maximum: Double, ward: String, phone: String, status: PendingGoalSnapshotStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.encounterID = encounterID
            self.summary = summary
            self.approved = approved
            self.maximum = maximum
            self.ward = ward
            self.phone = phone
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

        func canMoveTo(_ next: PendingGoalSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingGoalSnapshotStatus.cancelled
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

        func moveTo(_ next: PendingGoalSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending goal snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> PendingGoalSnapshot {
            return PendingGoalSnapshot(
                code: code,
                name: name,
                category: category,
                encounterID: encounterID,
                summary: summary,
                approved: approved,
                maximum: maximum,
                ward: ward,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending goal snapshot in status planned.
    static func newPendingGoalSnapshot(_ code: String, name: String) -> PendingGoalSnapshot {
        return PendingGoalSnapshot(
            code: code,
            name: name,
            category: "",
            encounterID: "",
            summary: "",
            approved: false,
            maximum: 0.0,
            ward: "",
            phone: "",
            status: PendingGoalSnapshotStatus.planned
        )
    }
}
