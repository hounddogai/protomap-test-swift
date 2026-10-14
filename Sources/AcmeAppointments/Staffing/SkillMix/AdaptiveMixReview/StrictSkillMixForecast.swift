import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix forecast is in its life cycle.
    enum StrictSkillMixForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a strict skill mix forecast and its current status.
    final class StrictSkillMixForecast {
        var code: String
        var label: String
        var ward: String
        var batchSize: Int
        var currency: String
        var cost: Double
        var pinned: Bool
        var limit: Int
        var status: StrictSkillMixForecastStatus

        init(code: String, label: String, ward: String, batchSize: Int, currency: String, cost: Double, pinned: Bool, limit: Int, status: StrictSkillMixForecastStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.batchSize = batchSize
            self.currency = currency
            self.cost = cost
            self.pinned = pinned
            self.limit = limit
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

        func canMoveTo(_ next: StrictSkillMixForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictSkillMixForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict skill mix forecast") \(code)"
        }

        func effectiveValue() -> Double {
            return ((cost - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixForecast {
            return StrictSkillMixForecast(
                code: code,
                label: label,
                ward: ward,
                batchSize: batchSize,
                currency: currency,
                cost: cost,
                pinned: pinned,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict skill mix forecast in status requested.
    static func newStrictSkillMixForecast(_ code: String, label: String) -> StrictSkillMixForecast {
        return StrictSkillMixForecast(
            code: code,
            label: label,
            ward: "",
            batchSize: 0,
            currency: "",
            cost: 0.0,
            pinned: false,
            limit: 0,
            status: StrictSkillMixForecastStatus.requested
        )
    }
}
