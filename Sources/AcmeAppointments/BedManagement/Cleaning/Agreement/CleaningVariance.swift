import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning variance is in its life cycle.
    enum CleaningVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A cleaning variance. Its code is unique within a tenant.
    final class CleaningVariance {
        var code: String
        var label: String
        var startsAt: Int
        var timezone: String
        var windowDays: Int
        var retries: Int
        var status: CleaningVarianceStatus

        init(code: String, label: String, startsAt: Int, timezone: String, windowDays: Int, retries: Int, status: CleaningVarianceStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.timezone = timezone
            self.windowDays = windowDays
            self.retries = retries
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

        func canMoveTo(_ next: CleaningVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CleaningVarianceStatus.inProgress || next == CleaningVarianceStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CleaningVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("cleaning variance") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(retries) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningVariance {
            return CleaningVariance(
                code: code,
                label: label,
                startsAt: startsAt,
                timezone: timezone,
                windowDays: windowDays,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning variance in status planned.
    static func newCleaningVariance(_ code: String, label: String) -> CleaningVariance {
        return CleaningVariance(
            code: code,
            label: label,
            startsAt: 0,
            timezone: "",
            windowDays: 0,
            retries: 0,
            status: CleaningVarianceStatus.planned
        )
    }
}
