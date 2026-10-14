import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending language forecast is in its life cycle.
    enum PendingLanguageForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending language forecast, with what the planners need to act on it.
    final class PendingLanguageForecast {
        var code: String
        var label: String
        var batchSize: Int
        var graceDays: Int
        var updatedAt: Int
        var country: String
        var channel: String
        var status: PendingLanguageForecastStatus

        init(code: String, label: String, batchSize: Int, graceDays: Int, updatedAt: Int, country: String, channel: String, status: PendingLanguageForecastStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.updatedAt = updatedAt
            self.country = country
            self.channel = channel
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

        func canMoveTo(_ next: PendingLanguageForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingLanguageForecastStatus.draining
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingLanguageForecastStatus.draining || next == PendingLanguageForecastStatus.stopped
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

        func moveTo(_ next: PendingLanguageForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending language forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending language forecast") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(graceDays) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PendingLanguageForecast {
            return PendingLanguageForecast(
                code: code,
                label: label,
                batchSize: batchSize,
                graceDays: graceDays,
                updatedAt: updatedAt,
                country: country,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending language forecast in status idle.
    static func newPendingLanguageForecast(_ code: String, label: String) -> PendingLanguageForecast {
        return PendingLanguageForecast(
            code: code,
            label: label,
            batchSize: 0,
            graceDays: 0,
            updatedAt: 0,
            country: "",
            channel: "",
            status: PendingLanguageForecastStatus.idle
        )
    }
}
