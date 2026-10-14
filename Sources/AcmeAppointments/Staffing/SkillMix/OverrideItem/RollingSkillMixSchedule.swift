import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling skill mix schedule is in its life cycle.
    enum RollingSkillMixScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling skill mix schedule and its current status.
    final class RollingSkillMixSchedule {
        var code: String
        var name: String
        var visitMinutes: Int
        var clinicianID: String
        var floorValue: Double
        var unit: String
        var refills: Int
        var graceDays: Int
        var score: Double
        var amount: Double
        var windowDays: Int
        var status: RollingSkillMixScheduleStatus

        init(code: String, name: String, visitMinutes: Int, clinicianID: String, floorValue: Double, unit: String, refills: Int, graceDays: Int, score: Double, amount: Double, windowDays: Int, status: RollingSkillMixScheduleStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.unit = unit
            self.refills = refills
            self.graceDays = graceDays
            self.score = score
            self.amount = amount
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingSkillMixScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingSkillMixScheduleStatus.queued || next == RollingSkillMixScheduleStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingSkillMixScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSkillMixScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling skill mix schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling skill mix schedule") \(code)"
        }

        func netExposure() -> Double {
            return ((amount + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSkillMixSchedule {
            return RollingSkillMixSchedule(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                floorValue: floorValue,
                unit: unit,
                refills: refills,
                graceDays: graceDays,
                score: score,
                amount: amount,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling skill mix schedule in status new.
    static func newRollingSkillMixSchedule(_ code: String, name: String) -> RollingSkillMixSchedule {
        return RollingSkillMixSchedule(
            code: code,
            name: name,
            visitMinutes: 0,
            clinicianID: "",
            floorValue: 0.0,
            unit: "",
            refills: 0,
            graceDays: 0,
            score: 0.0,
            amount: 0.0,
            windowDays: 0,
            status: RollingSkillMixScheduleStatus.new
        )
    }
}
