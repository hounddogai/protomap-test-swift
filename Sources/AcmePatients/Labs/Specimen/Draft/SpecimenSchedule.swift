import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen schedule is in its life cycle.
    enum SpecimenScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a specimen schedule and its current status.
    final class SpecimenSchedule {
        var code: String
        var title: String
        var visitMinutes: Int
        var copay: Double
        var payer: String
        var budget: Double
        var status: SpecimenScheduleStatus

        init(code: String, title: String, visitMinutes: Int, copay: Double, payer: String, budget: Double, status: SpecimenScheduleStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.payer = payer
            self.budget = budget
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

        func canMoveTo(_ next: SpecimenScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == SpecimenScheduleStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SpecimenScheduleStatus.completed || next == SpecimenScheduleStatus.cancelled
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

        func moveTo(_ next: SpecimenScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("specimen schedule") \(code)"
        }

        func projectedValue() -> Double {
            return ((copay + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenSchedule {
            return SpecimenSchedule(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                copay: copay,
                payer: payer,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen schedule in status planned.
    static func newSpecimenSchedule(_ code: String, title: String) -> SpecimenSchedule {
        return SpecimenSchedule(
            code: code,
            title: title,
            visitMinutes: 0,
            copay: 0.0,
            payer: "",
            budget: 0.0,
            status: SpecimenScheduleStatus.planned
        )
    }
}
