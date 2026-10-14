import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up cycle is in its life cycle.
    enum ScheduledFollowUpCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled follow up cycle and its current status.
    final class ScheduledFollowUpCycle {
        var code: String
        var title: String
        var windowDays: Int
        var visitMinutes: Int
        var approved: Bool
        var status: ScheduledFollowUpCycleStatus

        init(code: String, title: String, windowDays: Int, visitMinutes: Int, approved: Bool, status: ScheduledFollowUpCycleStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.approved = approved
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

        func canMoveTo(_ next: ScheduledFollowUpCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledFollowUpCycleStatus.done || next == ScheduledFollowUpCycleStatus.failed
            case .done:
                return next == ScheduledFollowUpCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFollowUpCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled follow up cycle") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(visitMinutes) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpCycle {
            return ScheduledFollowUpCycle(
                code: code,
                title: title,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled follow up cycle in status new.
    static func newScheduledFollowUpCycle(_ code: String, title: String) -> ScheduledFollowUpCycle {
        return ScheduledFollowUpCycle(
            code: code,
            title: title,
            windowDays: 0,
            visitMinutes: 0,
            approved: false,
            status: ScheduledFollowUpCycleStatus.new
        )
    }
}
