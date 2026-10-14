import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled formulary milestone is in its life cycle.
    enum ScheduledFormularyMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a scheduled formulary milestone and its current status.
    final class ScheduledFormularyMilestone {
        var code: String
        var title: String
        var ratio: Double
        var patientRef: String
        var procedureCode: String
        var createdAt: Int
        var acuity: Int
        var status: ScheduledFormularyMilestoneStatus

        init(code: String, title: String, ratio: Double, patientRef: String, procedureCode: String, createdAt: Int, acuity: Int, status: ScheduledFormularyMilestoneStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.createdAt = createdAt
            self.acuity = acuity
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

        func canMoveTo(_ next: ScheduledFormularyMilestoneStatus) -> Bool {
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
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ScheduledFormularyMilestoneStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFormularyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled formulary milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (Double(createdAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFormularyMilestone {
            return ScheduledFormularyMilestone(
                code: code,
                title: title,
                ratio: ratio,
                patientRef: patientRef,
                procedureCode: procedureCode,
                createdAt: createdAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled formulary milestone in status planned.
    static func newScheduledFormularyMilestone(_ code: String, title: String) -> ScheduledFormularyMilestone {
        return ScheduledFormularyMilestone(
            code: code,
            title: title,
            ratio: 0.0,
            patientRef: "",
            procedureCode: "",
            createdAt: 0,
            acuity: 0,
            status: ScheduledFormularyMilestoneStatus.planned
        )
    }
}
