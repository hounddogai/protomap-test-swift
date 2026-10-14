import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal snapshot is in its life cycle.
    enum GoalSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a goal snapshot and its current status.
    final class GoalSnapshot {
        var code: String
        var label: String
        var bed: String
        var unit: String
        var encounterID: String
        var floorValue: Double
        var graceDays: Int
        var threshold: Double
        var status: GoalSnapshotStatus

        init(code: String, label: String, bed: String, unit: String, encounterID: String, floorValue: Double, graceDays: Int, threshold: Double, status: GoalSnapshotStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.unit = unit
            self.encounterID = encounterID
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.threshold = threshold
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

        func canMoveTo(_ next: GoalSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == GoalSnapshotStatus.pending
            case .pending:
                return next == GoalSnapshotStatus.active || next == GoalSnapshotStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GoalSnapshotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(graceDays) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> GoalSnapshot {
            return GoalSnapshot(
                code: code,
                label: label,
                bed: bed,
                unit: unit,
                encounterID: encounterID,
                floorValue: floorValue,
                graceDays: graceDays,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a goal snapshot in status draft.
    static func newGoalSnapshot(_ code: String, label: String) -> GoalSnapshot {
        return GoalSnapshot(
            code: code,
            label: label,
            bed: "",
            unit: "",
            encounterID: "",
            floorValue: 0.0,
            graceDays: 0,
            threshold: 0.0,
            status: GoalSnapshotStatus.draft
        )
    }
}
