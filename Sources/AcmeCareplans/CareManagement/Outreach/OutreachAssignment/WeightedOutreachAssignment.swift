import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted outreach assignment is in its life cycle.
    enum WeightedOutreachAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a weighted outreach assignment and its current status.
    final class WeightedOutreachAssignment {
        var code: String
        var name: String
        var version: Int
        var discount: Double
        var rate: Double
        var encounterID: String
        var copay: Double
        var weight: Double
        var reviewer: String
        var status: WeightedOutreachAssignmentStatus

        init(code: String, name: String, version: Int, discount: Double, rate: Double, encounterID: String, copay: Double, weight: Double, reviewer: String, status: WeightedOutreachAssignmentStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.discount = discount
            self.rate = rate
            self.encounterID = encounterID
            self.copay = copay
            self.weight = weight
            self.reviewer = reviewer
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

        func canMoveTo(_ next: WeightedOutreachAssignmentStatus) -> Bool {
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
                return next == WeightedOutreachAssignmentStatus.inProgress
            case .inProgress:
                return next == WeightedOutreachAssignmentStatus.completed || next == WeightedOutreachAssignmentStatus.cancelled
            case .completed:
                return next == WeightedOutreachAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOutreachAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted outreach assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((discount - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOutreachAssignment {
            return WeightedOutreachAssignment(
                code: code,
                name: name,
                version: version,
                discount: discount,
                rate: rate,
                encounterID: encounterID,
                copay: copay,
                weight: weight,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted outreach assignment in status planned.
    static func newWeightedOutreachAssignment(_ code: String, name: String) -> WeightedOutreachAssignment {
        return WeightedOutreachAssignment(
            code: code,
            name: name,
            version: 0,
            discount: 0.0,
            rate: 0.0,
            encounterID: "",
            copay: 0.0,
            weight: 0.0,
            reviewer: "",
            status: WeightedOutreachAssignmentStatus.planned
        )
    }
}
