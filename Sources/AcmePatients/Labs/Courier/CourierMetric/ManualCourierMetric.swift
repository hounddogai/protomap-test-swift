import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual courier metric is in its life cycle.
    enum ManualCourierMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One manual courier metric, with what the planners need to act on it.
    final class ManualCourierMetric {
        var code: String
        var title: String
        var threshold: Double
        var tags: [String]
        var retries: Int
        var durationMinutes: Int
        var maximum: Double
        var startsAt: Int
        var status: ManualCourierMetricStatus

        init(code: String, title: String, threshold: Double, tags: [String], retries: Int, durationMinutes: Int, maximum: Double, startsAt: Int, status: ManualCourierMetricStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.tags = tags
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCourierMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualCourierMetricStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualCourierMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual courier metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((maximum - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCourierMetric {
            return ManualCourierMetric(
                code: code,
                title: title,
                threshold: threshold,
                tags: tags,
                retries: retries,
                durationMinutes: durationMinutes,
                maximum: maximum,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual courier metric in status open.
    static func newManualCourierMetric(_ code: String, title: String) -> ManualCourierMetric {
        return ManualCourierMetric(
            code: code,
            title: title,
            threshold: 0.0,
            tags: [],
            retries: 0,
            durationMinutes: 0,
            maximum: 0.0,
            startsAt: 0,
            status: ManualCourierMetricStatus.`open`
        )
    }
}
