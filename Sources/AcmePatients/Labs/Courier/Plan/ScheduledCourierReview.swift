import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled courier review is in its life cycle.
    enum ScheduledCourierReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled courier review as the courier team keeps it.
    final class ScheduledCourierReview {
        var code: String
        var name: String
        var windowDays: Int
        var checksum: String
        var ceiling: Double
        var status: ScheduledCourierReviewStatus

        init(code: String, name: String, windowDays: Int, checksum: String, ceiling: Double, status: ScheduledCourierReviewStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.checksum = checksum
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ScheduledCourierReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledCourierReviewStatus.running || next == ScheduledCourierReviewStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: ScheduledCourierReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled courier review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCourierReview {
            return ScheduledCourierReview(
                code: code,
                name: name,
                windowDays: windowDays,
                checksum: checksum,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled courier review in status new.
    static func newScheduledCourierReview(_ code: String, name: String) -> ScheduledCourierReview {
        return ScheduledCourierReview(
            code: code,
            name: name,
            windowDays: 0,
            checksum: "",
            ceiling: 0.0,
            status: ScheduledCourierReviewStatus.new
        )
    }
}
