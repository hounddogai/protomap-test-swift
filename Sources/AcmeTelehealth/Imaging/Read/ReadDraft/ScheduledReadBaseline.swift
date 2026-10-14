import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled read baseline is in its life cycle.
    enum ScheduledReadBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled read baseline and its current status.
    final class ScheduledReadBaseline {
        var code: String
        var title: String
        var attempts: Int
        var summary: String
        var timezone: String
        var region: String
        var margin: Double
        var checksum: String
        var unit: String
        var windowDays: Int
        var source: String
        var status: ScheduledReadBaselineStatus

        init(code: String, title: String, attempts: Int, summary: String, timezone: String, region: String, margin: Double, checksum: String, unit: String, windowDays: Int, source: String, status: ScheduledReadBaselineStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.summary = summary
            self.timezone = timezone
            self.region = region
            self.margin = margin
            self.checksum = checksum
            self.unit = unit
            self.windowDays = windowDays
            self.source = source
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

        func canMoveTo(_ next: ScheduledReadBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledReadBaselineStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return (Double(windowDays) * margin * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReadBaseline {
            return ScheduledReadBaseline(
                code: code,
                title: title,
                attempts: attempts,
                summary: summary,
                timezone: timezone,
                region: region,
                margin: margin,
                checksum: checksum,
                unit: unit,
                windowDays: windowDays,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled read baseline in status proposed.
    static func newScheduledReadBaseline(_ code: String, title: String) -> ScheduledReadBaseline {
        return ScheduledReadBaseline(
            code: code,
            title: title,
            attempts: 0,
            summary: "",
            timezone: "",
            region: "",
            margin: 0.0,
            checksum: "",
            unit: "",
            windowDays: 0,
            source: "",
            status: ScheduledReadBaselineStatus.proposed
        )
    }
}
