import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach metric is in its life cycle.
    enum OutreachMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One outreach metric, with what the planners need to act on it.
    final class OutreachMetric {
        var code: String
        var name: String
        var pinned: Bool
        var threshold: Double
        var updatedAt: Int
        var ownerID: String
        var status: OutreachMetricStatus

        init(code: String, name: String, pinned: Bool, threshold: Double, updatedAt: Int, ownerID: String, status: OutreachMetricStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.ownerID = ownerID
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

        func canMoveTo(_ next: OutreachMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == OutreachMetricStatus.ready
            case .warming:
                return next == OutreachMetricStatus.draining
            case .ready:
                return next == OutreachMetricStatus.stopped
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

        func moveTo(_ next: OutreachMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("outreach metric") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(updatedAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> OutreachMetric {
            return OutreachMetric(
                code: code,
                name: name,
                pinned: pinned,
                threshold: threshold,
                updatedAt: updatedAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach metric in status idle.
    static func newOutreachMetric(_ code: String, name: String) -> OutreachMetric {
        return OutreachMetric(
            code: code,
            name: name,
            pinned: false,
            threshold: 0.0,
            updatedAt: 0,
            ownerID: "",
            status: OutreachMetricStatus.idle
        )
    }
}
