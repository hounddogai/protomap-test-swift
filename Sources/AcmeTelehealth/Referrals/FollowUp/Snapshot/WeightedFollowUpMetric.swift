import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted follow up metric is in its life cycle.
    enum WeightedFollowUpMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted follow up metric. Its code is unique within a tenant.
    final class WeightedFollowUpMetric {
        var code: String
        var title: String
        var startsAt: Int
        var retries: Int
        var checksum: String
        var region: String
        var batchSize: Int
        var status: WeightedFollowUpMetricStatus

        init(code: String, title: String, startsAt: Int, retries: Int, checksum: String, region: String, batchSize: Int, status: WeightedFollowUpMetricStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.retries = retries
            self.checksum = checksum
            self.region = region
            self.batchSize = batchSize
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

        func canMoveTo(_ next: WeightedFollowUpMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedFollowUpMetricStatus.expired
            case .granted:
                return next == WeightedFollowUpMetricStatus.revoked
            case .revoked:
                return next == WeightedFollowUpMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFollowUpMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted follow up metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted follow up metric") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(startsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFollowUpMetric {
            return WeightedFollowUpMetric(
                code: code,
                title: title,
                startsAt: startsAt,
                retries: retries,
                checksum: checksum,
                region: region,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted follow up metric in status requested.
    static func newWeightedFollowUpMetric(_ code: String, title: String) -> WeightedFollowUpMetric {
        return WeightedFollowUpMetric(
            code: code,
            title: title,
            startsAt: 0,
            retries: 0,
            checksum: "",
            region: "",
            batchSize: 0,
            status: WeightedFollowUpMetricStatus.requested
        )
    }
}
