import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped cleaning forecast is in its life cycle.
    enum CappedCleaningForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped cleaning forecast, with what the planners need to act on it.
    final class CappedCleaningForecast {
        var code: String
        var title: String
        var acuity: Int
        var batchSize: Int
        var source: String
        var margin: Double
        var copay: Double
        var summary: String
        var expiresAt: Int
        var status: CappedCleaningForecastStatus

        init(code: String, title: String, acuity: Int, batchSize: Int, source: String, margin: Double, copay: Double, summary: String, expiresAt: Int, status: CappedCleaningForecastStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.batchSize = batchSize
            self.source = source
            self.margin = margin
            self.copay = copay
            self.summary = summary
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedCleaningForecastStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedCleaningForecastStatus.draining || next == CappedCleaningForecastStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedCleaningForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped cleaning forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCleaningForecast {
            return CappedCleaningForecast(
                code: code,
                title: title,
                acuity: acuity,
                batchSize: batchSize,
                source: source,
                margin: margin,
                copay: copay,
                summary: summary,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped cleaning forecast in status idle.
    static func newCappedCleaningForecast(_ code: String, title: String) -> CappedCleaningForecast {
        return CappedCleaningForecast(
            code: code,
            title: title,
            acuity: 0,
            batchSize: 0,
            source: "",
            margin: 0.0,
            copay: 0.0,
            summary: "",
            expiresAt: 0,
            status: CappedCleaningForecastStatus.idle
        )
    }
}
