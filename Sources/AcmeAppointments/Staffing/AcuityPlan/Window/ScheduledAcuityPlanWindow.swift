import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled acuity plan window is in its life cycle.
    enum ScheduledAcuityPlanWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled acuity plan window and its current status.
    final class ScheduledAcuityPlanWindow {
        var code: String
        var title: String
        var visible: Bool
        var batchSize: Int
        var description: String
        var diagnosisCode: String
        var ownerID: String
        var status: ScheduledAcuityPlanWindowStatus

        init(code: String, title: String, visible: Bool, batchSize: Int, description: String, diagnosisCode: String, ownerID: String, status: ScheduledAcuityPlanWindowStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.batchSize = batchSize
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ScheduledAcuityPlanWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledAcuityPlanWindowStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledAcuityPlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled acuity plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> ScheduledAcuityPlanWindow {
            return ScheduledAcuityPlanWindow(
                code: code,
                title: title,
                visible: visible,
                batchSize: batchSize,
                description: description,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled acuity plan window in status proposed.
    static func newScheduledAcuityPlanWindow(_ code: String, title: String) -> ScheduledAcuityPlanWindow {
        return ScheduledAcuityPlanWindow(
            code: code,
            title: title,
            visible: false,
            batchSize: 0,
            description: "",
            diagnosisCode: "",
            ownerID: "",
            status: ScheduledAcuityPlanWindowStatus.proposed
        )
    }
}
