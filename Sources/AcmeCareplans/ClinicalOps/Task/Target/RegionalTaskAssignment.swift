import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional task assignment is in its life cycle.
    enum RegionalTaskAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional task assignment as the task team keeps it.
    final class RegionalTaskAssignment {
        var code: String
        var title: String
        var pinned: Bool
        var channel: String
        var currency: String
        var ceiling: Double
        var name: String
        var windowDays: Int
        var cost: Double
        var status: RegionalTaskAssignmentStatus

        init(code: String, title: String, pinned: Bool, channel: String, currency: String, ceiling: Double, name: String, windowDays: Int, cost: Double, status: RegionalTaskAssignmentStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.channel = channel
            self.currency = currency
            self.ceiling = ceiling
            self.name = name
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RegionalTaskAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalTaskAssignmentStatus.queued || next == RegionalTaskAssignmentStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RegionalTaskAssignmentStatus.done
            case .done:
                return next == RegionalTaskAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalTaskAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional task assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(windowDays) + cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalTaskAssignment {
            return RegionalTaskAssignment(
                code: code,
                title: title,
                pinned: pinned,
                channel: channel,
                currency: currency,
                ceiling: ceiling,
                name: name,
                windowDays: windowDays,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional task assignment in status new.
    static func newRegionalTaskAssignment(_ code: String, title: String) -> RegionalTaskAssignment {
        return RegionalTaskAssignment(
            code: code,
            title: title,
            pinned: false,
            channel: "",
            currency: "",
            ceiling: 0.0,
            name: "",
            windowDays: 0,
            cost: 0.0,
            status: RegionalTaskAssignmentStatus.new
        )
    }
}
