import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global follow up metric is in its life cycle.
    enum GlobalFollowUpMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global follow up metric. Its code is unique within a tenant.
    final class GlobalFollowUpMetric {
        var code: String
        var name: String
        var capacity: Int
        var ratio: Double
        var summary: String
        var status: GlobalFollowUpMetricStatus

        init(code: String, name: String, capacity: Int, ratio: Double, summary: String, status: GlobalFollowUpMetricStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.ratio = ratio
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalFollowUpMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalFollowUpMetricStatus.revoked
            case .granted:
                return next == GlobalFollowUpMetricStatus.revoked || next == GlobalFollowUpMetricStatus.expired
            case .revoked:
                return next == GlobalFollowUpMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFollowUpMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global follow up metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((ratio - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFollowUpMetric {
            return GlobalFollowUpMetric(
                code: code,
                name: name,
                capacity: capacity,
                ratio: ratio,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global follow up metric in status requested.
    static func newGlobalFollowUpMetric(_ code: String, name: String) -> GlobalFollowUpMetric {
        return GlobalFollowUpMetric(
            code: code,
            name: name,
            capacity: 0,
            ratio: 0.0,
            summary: "",
            status: GlobalFollowUpMetricStatus.requested
        )
    }
}
