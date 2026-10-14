import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding forecast is in its life cycle.
    enum RoundingForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rounding forecast and its current status.
    final class RoundingForecast {
        var code: String
        var label: String
        var limit: Int
        var graceDays: Int
        var attributes: [String: String]
        var endsAt: Int
        var status: RoundingForecastStatus

        init(code: String, label: String, limit: Int, graceDays: Int, attributes: [String: String], endsAt: Int, status: RoundingForecastStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.graceDays = graceDays
            self.attributes = attributes
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingForecastStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RoundingForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedTotal() -> Double {
            return ((Double(limit) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingForecast {
            return RoundingForecast(
                code: code,
                label: label,
                limit: limit,
                graceDays: graceDays,
                attributes: attributes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rounding forecast in status new.
    static func newRoundingForecast(_ code: String, label: String) -> RoundingForecast {
        return RoundingForecast(
            code: code,
            label: label,
            limit: 0,
            graceDays: 0,
            attributes: [:],
            endsAt: 0,
            status: RoundingForecastStatus.new
        )
    }
}
