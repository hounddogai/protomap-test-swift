import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime forecast is in its life cycle.
    enum OvertimeForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One overtime forecast, with what the planners need to act on it.
    final class OvertimeForecast {
        var code: String
        var label: String
        var visible: Bool
        var ward: String
        var refills: Int
        var visitMinutes: Int
        var status: OvertimeForecastStatus

        init(code: String, label: String, visible: Bool, ward: String, refills: Int, visitMinutes: Int, status: OvertimeForecastStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.ward = ward
            self.refills = refills
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: OvertimeForecastStatus) -> Bool {
            switch status {
            case .requested:
                return next == OvertimeForecastStatus.granted || next == OvertimeForecastStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == OvertimeForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("overtime forecast") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(visitMinutes) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeForecast {
            return OvertimeForecast(
                code: code,
                label: label,
                visible: visible,
                ward: ward,
                refills: refills,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime forecast in status requested.
    static func newOvertimeForecast(_ code: String, label: String) -> OvertimeForecast {
        return OvertimeForecast(
            code: code,
            label: label,
            visible: false,
            ward: "",
            refills: 0,
            visitMinutes: 0,
            status: OvertimeForecastStatus.requested
        )
    }
}
