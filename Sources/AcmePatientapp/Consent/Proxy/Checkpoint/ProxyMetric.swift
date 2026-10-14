import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy metric is in its life cycle.
    enum ProxyMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a proxy metric and its current status.
    final class ProxyMetric {
        var code: String
        var name: String
        var startsAt: Int
        var channel: String
        var batchSize: Int
        var version: Int
        var country: String
        var budget: Double
        var status: ProxyMetricStatus

        init(code: String, name: String, startsAt: Int, channel: String, batchSize: Int, version: Int, country: String, budget: Double, status: ProxyMetricStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.channel = channel
            self.batchSize = batchSize
            self.version = version
            self.country = country
            self.budget = budget
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

        func canMoveTo(_ next: ProxyMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ProxyMetricStatus.completed || next == ProxyMetricStatus.cancelled
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

        func moveTo(_ next: ProxyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("proxy metric") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(batchSize) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ProxyMetric {
            return ProxyMetric(
                code: code,
                name: name,
                startsAt: startsAt,
                channel: channel,
                batchSize: batchSize,
                version: version,
                country: country,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a proxy metric in status planned.
    static func newProxyMetric(_ code: String, name: String) -> ProxyMetric {
        return ProxyMetric(
            code: code,
            name: name,
            startsAt: 0,
            channel: "",
            batchSize: 0,
            version: 0,
            country: "",
            budget: 0.0,
            status: ProxyMetricStatus.planned
        )
    }
}
