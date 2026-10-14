import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled worklist tier is in its life cycle.
    enum ScheduledWorklistTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled worklist tier. Its code is unique within a tenant.
    final class ScheduledWorklistTier {
        var code: String
        var title: String
        var durationMinutes: Int
        var ratio: Double
        var label: String
        var windowDays: Int
        var visitMinutes: Int
        var channel: String
        var discount: Double
        var status: ScheduledWorklistTierStatus

        init(code: String, title: String, durationMinutes: Int, ratio: Double, label: String, windowDays: Int, visitMinutes: Int, channel: String, discount: Double, status: ScheduledWorklistTierStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.label = label
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledWorklistTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledWorklistTierStatus.draining
            case .ready:
                return next == ScheduledWorklistTierStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledWorklistTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled worklist tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(windowDays) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledWorklistTier {
            return ScheduledWorklistTier(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                ratio: ratio,
                label: label,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                channel: channel,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled worklist tier in status idle.
    static func newScheduledWorklistTier(_ code: String, title: String) -> ScheduledWorklistTier {
        return ScheduledWorklistTier(
            code: code,
            title: title,
            durationMinutes: 0,
            ratio: 0.0,
            label: "",
            windowDays: 0,
            visitMinutes: 0,
            channel: "",
            discount: 0.0,
            status: ScheduledWorklistTierStatus.idle
        )
    }
}
