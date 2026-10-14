import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set profile is in its life cycle.
    enum SeasonalOrderSetProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal order set profile as the order set team keeps it.
    final class SeasonalOrderSetProfile {
        var code: String
        var label: String
        var category: String
        var ceiling: Double
        var capacity: Int
        var facility: String
        var revision: Int
        var encounterID: String
        var status: SeasonalOrderSetProfileStatus

        init(code: String, label: String, category: String, ceiling: Double, capacity: Int, facility: String, revision: Int, encounterID: String, status: SeasonalOrderSetProfileStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.ceiling = ceiling
            self.capacity = capacity
            self.facility = facility
            self.revision = revision
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SeasonalOrderSetProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalOrderSetProfileStatus.completed
            case .scheduled:
                return next == SeasonalOrderSetProfileStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SeasonalOrderSetProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalOrderSetProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOrderSetProfile {
            return SeasonalOrderSetProfile(
                code: code,
                label: label,
                category: category,
                ceiling: ceiling,
                capacity: capacity,
                facility: facility,
                revision: revision,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal order set profile in status planned.
    static func newSeasonalOrderSetProfile(_ code: String, label: String) -> SeasonalOrderSetProfile {
        return SeasonalOrderSetProfile(
            code: code,
            label: label,
            category: "",
            ceiling: 0.0,
            capacity: 0,
            facility: "",
            revision: 0,
            encounterID: "",
            status: SeasonalOrderSetProfileStatus.planned
        )
    }
}
