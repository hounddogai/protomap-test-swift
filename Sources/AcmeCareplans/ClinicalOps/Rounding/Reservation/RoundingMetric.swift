import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding metric is in its life cycle.
    enum RoundingMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rounding metric, with what the planners need to act on it.
    final class RoundingMetric {
        var code: String
        var name: String
        var priority: Int
        var version: Int
        var retries: Int
        var status: RoundingMetricStatus

        init(code: String, name: String, priority: Int, version: Int, retries: Int, status: RoundingMetricStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.version = version
            self.retries = retries
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

        func canMoveTo(_ next: RoundingMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RoundingMetricStatus.resolved || next == RoundingMetricStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RoundingMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return ((Double(retries) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingMetric {
            return RoundingMetric(
                code: code,
                name: name,
                priority: priority,
                version: version,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding metric in status open.
    static func newRoundingMetric(_ code: String, name: String) -> RoundingMetric {
        return RoundingMetric(
            code: code,
            name: name,
            priority: 0,
            version: 0,
            retries: 0,
            status: RoundingMetricStatus.`open`
        )
    }
}
