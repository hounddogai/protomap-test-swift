import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol metric is in its life cycle.
    enum CareProtocolMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol metric as the care protocol team keeps it.
    final class CareProtocolMetric {
        var code: String
        var name: String
        var bed: String
        var batchSize: Int
        var graceDays: Int
        var threshold: Double
        var region: String
        var maximum: Double
        var locale: String
        var retries: Int
        var status: CareProtocolMetricStatus

        init(code: String, name: String, bed: String, batchSize: Int, graceDays: Int, threshold: Double, region: String, maximum: Double, locale: String, retries: Int, status: CareProtocolMetricStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.threshold = threshold
            self.region = region
            self.maximum = maximum
            self.locale = locale
            self.retries = retries
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

        func canMoveTo(_ next: CareProtocolMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolMetricStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolMetricStatus.draining || next == CareProtocolMetricStatus.stopped
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

        func moveTo(_ next: CareProtocolMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(retries) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolMetric {
            return CareProtocolMetric(
                code: code,
                name: name,
                bed: bed,
                batchSize: batchSize,
                graceDays: graceDays,
                threshold: threshold,
                region: region,
                maximum: maximum,
                locale: locale,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care protocol metric in status idle.
    static func newCareProtocolMetric(_ code: String, name: String) -> CareProtocolMetric {
        return CareProtocolMetric(
            code: code,
            name: name,
            bed: "",
            batchSize: 0,
            graceDays: 0,
            threshold: 0.0,
            region: "",
            maximum: 0.0,
            locale: "",
            retries: 0,
            status: CareProtocolMetricStatus.idle
        )
    }
}
