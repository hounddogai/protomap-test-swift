import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled panel group is in its life cycle.
    enum ScheduledPanelGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled panel group and its current status.
    final class ScheduledPanelGroup {
        var code: String
        var title: String
        var priority: Int
        var ward: String
        var cost: Double
        var status: ScheduledPanelGroupStatus

        init(code: String, title: String, priority: Int, ward: String, cost: Double, status: ScheduledPanelGroupStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.ward = ward
            self.cost = cost
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

        func canMoveTo(_ next: ScheduledPanelGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledPanelGroupStatus.queued || next == ScheduledPanelGroupStatus.failed
            case .queued:
                return next == ScheduledPanelGroupStatus.done || next == ScheduledPanelGroupStatus.failed
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: ScheduledPanelGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled panel group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((cost - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPanelGroup {
            return ScheduledPanelGroup(
                code: code,
                title: title,
                priority: priority,
                ward: ward,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled panel group in status new.
    static func newScheduledPanelGroup(_ code: String, title: String) -> ScheduledPanelGroup {
        return ScheduledPanelGroup(
            code: code,
            title: title,
            priority: 0,
            ward: "",
            cost: 0.0,
            status: ScheduledPanelGroupStatus.new
        )
    }
}
