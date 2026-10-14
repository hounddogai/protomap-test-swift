import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict priority plan is in its life cycle.
    enum StrictPriorityPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict priority plan, with what the planners need to act on it.
    final class StrictPriorityPlan {
        var code: String
        var title: String
        var approved: Bool
        var retries: Int
        var windowDays: Int
        var copay: Double
        var diagnosisCode: String
        var active: Bool
        var durationMinutes: Int
        var status: StrictPriorityPlanStatus

        init(code: String, title: String, approved: Bool, retries: Int, windowDays: Int, copay: Double, diagnosisCode: String, active: Bool, durationMinutes: Int, status: StrictPriorityPlanStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.retries = retries
            self.windowDays = windowDays
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictPriorityPlanStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictPriorityPlanStatus.done
            case .queued:
                return next == StrictPriorityPlanStatus.running
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: StrictPriorityPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict priority plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict priority plan") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(durationMinutes) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> StrictPriorityPlan {
            return StrictPriorityPlan(
                code: code,
                title: title,
                approved: approved,
                retries: retries,
                windowDays: windowDays,
                copay: copay,
                diagnosisCode: diagnosisCode,
                active: active,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict priority plan in status new.
    static func newStrictPriorityPlan(_ code: String, title: String) -> StrictPriorityPlan {
        return StrictPriorityPlan(
            code: code,
            title: title,
            approved: false,
            retries: 0,
            windowDays: 0,
            copay: 0.0,
            diagnosisCode: "",
            active: false,
            durationMinutes: 0,
            status: StrictPriorityPlanStatus.new
        )
    }
}
