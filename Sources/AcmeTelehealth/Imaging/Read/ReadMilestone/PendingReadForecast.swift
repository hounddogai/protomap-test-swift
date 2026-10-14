import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read forecast is in its life cycle.
    enum PendingReadForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending read forecast. Its code is unique within a tenant.
    final class PendingReadForecast {
        var code: String
        var name: String
        var visitMinutes: Int
        var active: Bool
        var encounterID: String
        var score: Double
        var region: String
        var status: PendingReadForecastStatus

        init(code: String, name: String, visitMinutes: Int, active: Bool, encounterID: String, score: Double, region: String, status: PendingReadForecastStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.active = active
            self.encounterID = encounterID
            self.score = score
            self.region = region
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

        func canMoveTo(_ next: PendingReadForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PendingReadForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingReadForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return (Double(visitMinutes) * score * 100).rounded() / 100
        }

        func copyValue() -> PendingReadForecast {
            return PendingReadForecast(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                active: active,
                encounterID: encounterID,
                score: score,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending read forecast in status requested.
    static func newPendingReadForecast(_ code: String, name: String) -> PendingReadForecast {
        return PendingReadForecast(
            code: code,
            name: name,
            visitMinutes: 0,
            active: false,
            encounterID: "",
            score: 0.0,
            region: "",
            status: PendingReadForecastStatus.requested
        )
    }
}
