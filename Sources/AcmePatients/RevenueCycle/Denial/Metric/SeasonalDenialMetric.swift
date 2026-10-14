import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal denial metric is in its life cycle.
    enum SeasonalDenialMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal denial metric as the denial team keeps it.
    final class SeasonalDenialMetric {
        var code: String
        var title: String
        var batchSize: Int
        var cost: Double
        var revision: Int
        var capacity: Int
        var weight: Double
        var description: String
        var windowDays: Int
        var visitMinutes: Int
        var copay: Double
        var status: SeasonalDenialMetricStatus

        init(code: String, title: String, batchSize: Int, cost: Double, revision: Int, capacity: Int, weight: Double, description: String, windowDays: Int, visitMinutes: Int, copay: Double, status: SeasonalDenialMetricStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.cost = cost
            self.revision = revision
            self.capacity = capacity
            self.weight = weight
            self.description = description
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.copay = copay
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

        func canMoveTo(_ next: SeasonalDenialMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalDenialMetricStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == SeasonalDenialMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalDenialMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal denial metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return (copay * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDenialMetric {
            return SeasonalDenialMetric(
                code: code,
                title: title,
                batchSize: batchSize,
                cost: cost,
                revision: revision,
                capacity: capacity,
                weight: weight,
                description: description,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal denial metric in status requested.
    static func newSeasonalDenialMetric(_ code: String, title: String) -> SeasonalDenialMetric {
        return SeasonalDenialMetric(
            code: code,
            title: title,
            batchSize: 0,
            cost: 0.0,
            revision: 0,
            capacity: 0,
            weight: 0.0,
            description: "",
            windowDays: 0,
            visitMinutes: 0,
            copay: 0.0,
            status: SeasonalDenialMetricStatus.requested
        )
    }
}
