import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy forecast is in its life cycle.
    enum ProxyForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One proxy forecast, with what the planners need to act on it.
    final class ProxyForecast {
        var code: String
        var name: String
        var margin: Double
        var updatedAt: Int
        var encounterID: String
        var ratio: Double
        var ownerID: String
        var status: ProxyForecastStatus

        init(code: String, name: String, margin: Double, updatedAt: Int, encounterID: String, ratio: Double, ownerID: String, status: ProxyForecastStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.ratio = ratio
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProxyForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((ratio - margin) * 100).rounded() / 100
        }

        func copyValue() -> ProxyForecast {
            return ProxyForecast(
                code: code,
                name: name,
                margin: margin,
                updatedAt: updatedAt,
                encounterID: encounterID,
                ratio: ratio,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy forecast in status created.
    static func newProxyForecast(_ code: String, name: String) -> ProxyForecast {
        return ProxyForecast(
            code: code,
            name: name,
            margin: 0.0,
            updatedAt: 0,
            encounterID: "",
            ratio: 0.0,
            ownerID: "",
            status: ProxyForecastStatus.created
        )
    }
}
