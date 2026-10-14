import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy reference range forecast is in its life cycle.
    enum LegacyReferenceRangeForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy reference range forecast, with what the planners need to act on it.
    final class LegacyReferenceRangeForecast {
        var code: String
        var label: String
        var timezone: String
        var visible: Bool
        var capacity: Int
        var status: LegacyReferenceRangeForecastStatus

        init(code: String, label: String, timezone: String, visible: Bool, capacity: Int, status: LegacyReferenceRangeForecastStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.visible = visible
            self.capacity = capacity
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

        func canMoveTo(_ next: LegacyReferenceRangeForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LegacyReferenceRangeForecastStatus.revoked || next == LegacyReferenceRangeForecastStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LegacyReferenceRangeForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy reference range forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> LegacyReferenceRangeForecast {
            return LegacyReferenceRangeForecast(
                code: code,
                label: label,
                timezone: timezone,
                visible: visible,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy reference range forecast in status requested.
    static func newLegacyReferenceRangeForecast(_ code: String, label: String) -> LegacyReferenceRangeForecast {
        return LegacyReferenceRangeForecast(
            code: code,
            label: label,
            timezone: "",
            visible: false,
            capacity: 0,
            status: LegacyReferenceRangeForecastStatus.requested
        )
    }
}
