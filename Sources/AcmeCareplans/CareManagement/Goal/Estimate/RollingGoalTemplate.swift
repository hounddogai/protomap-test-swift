import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling goal template is in its life cycle.
    enum RollingGoalTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling goal template and its current status.
    final class RollingGoalTemplate {
        var code: String
        var label: String
        var ownerID: String
        var unit: String
        var version: Int
        var archived: Bool
        var visitMinutes: Int
        var description: String
        var status: RollingGoalTemplateStatus

        init(code: String, label: String, ownerID: String, unit: String, version: Int, archived: Bool, visitMinutes: Int, description: String, status: RollingGoalTemplateStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.unit = unit
            self.version = version
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.description = description
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

        func canMoveTo(_ next: RollingGoalTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingGoalTemplateStatus.completed || next == RollingGoalTemplateStatus.cancelled
            case .inProgress:
                return next == RollingGoalTemplateStatus.completed
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

        func moveTo(_ next: RollingGoalTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling goal template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("rolling goal template") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(version) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingGoalTemplate {
            return RollingGoalTemplate(
                code: code,
                label: label,
                ownerID: ownerID,
                unit: unit,
                version: version,
                archived: archived,
                visitMinutes: visitMinutes,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling goal template in status planned.
    static func newRollingGoalTemplate(_ code: String, label: String) -> RollingGoalTemplate {
        return RollingGoalTemplate(
            code: code,
            label: label,
            ownerID: "",
            unit: "",
            version: 0,
            archived: false,
            visitMinutes: 0,
            description: "",
            status: RollingGoalTemplateStatus.planned
        )
    }
}
