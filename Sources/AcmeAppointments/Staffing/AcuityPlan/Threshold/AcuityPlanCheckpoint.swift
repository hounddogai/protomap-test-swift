import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan checkpoint is in its life cycle.
    enum AcuityPlanCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A acuity plan checkpoint as the acuity plan team keeps it.
    final class AcuityPlanCheckpoint {
        var code: String
        var name: String
        var discount: Double
        var floorValue: Double
        var bed: String
        var title: String
        var attempts: Int
        var createdAt: Int
        var updatedAt: Int
        var approved: Bool
        var timezone: String
        var status: AcuityPlanCheckpointStatus

        init(code: String, name: String, discount: Double, floorValue: Double, bed: String, title: String, attempts: Int, createdAt: Int, updatedAt: Int, approved: Bool, timezone: String, status: AcuityPlanCheckpointStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.floorValue = floorValue
            self.bed = bed
            self.title = title
            self.attempts = attempts
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.approved = approved
            self.timezone = timezone
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

        func canMoveTo(_ next: AcuityPlanCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == AcuityPlanCheckpointStatus.scheduled || next == AcuityPlanCheckpointStatus.inProgress
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AcuityPlanCheckpointStatus.cancelled
            case .completed:
                return next == AcuityPlanCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return (Double(updatedAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanCheckpoint {
            return AcuityPlanCheckpoint(
                code: code,
                name: name,
                discount: discount,
                floorValue: floorValue,
                bed: bed,
                title: title,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                approved: approved,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan checkpoint in status planned.
    static func newAcuityPlanCheckpoint(_ code: String, name: String) -> AcuityPlanCheckpoint {
        return AcuityPlanCheckpoint(
            code: code,
            name: name,
            discount: 0.0,
            floorValue: 0.0,
            bed: "",
            title: "",
            attempts: 0,
            createdAt: 0,
            updatedAt: 0,
            approved: false,
            timezone: "",
            status: AcuityPlanCheckpointStatus.planned
        )
    }
}
