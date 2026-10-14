import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding request is in its life cycle.
    enum SeasonalRoundingRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal rounding request as the rounding team keeps it.
    final class SeasonalRoundingRequest {
        var code: String
        var name: String
        var active: Bool
        var unit: String
        var weight: Double
        var source: String
        var maximum: Double
        var segment: String
        var ward: String
        var graceDays: Int
        var status: SeasonalRoundingRequestStatus

        init(code: String, name: String, active: Bool, unit: String, weight: Double, source: String, maximum: Double, segment: String, ward: String, graceDays: Int, status: SeasonalRoundingRequestStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.unit = unit
            self.weight = weight
            self.source = source
            self.maximum = maximum
            self.segment = segment
            self.ward = ward
            self.graceDays = graceDays
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

        func canMoveTo(_ next: SeasonalRoundingRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalRoundingRequestStatus.published || next == SeasonalRoundingRequestStatus.retired
            case .published:
                return next == SeasonalRoundingRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRoundingRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((maximum + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRoundingRequest {
            return SeasonalRoundingRequest(
                code: code,
                name: name,
                active: active,
                unit: unit,
                weight: weight,
                source: source,
                maximum: maximum,
                segment: segment,
                ward: ward,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal rounding request in status created.
    static func newSeasonalRoundingRequest(_ code: String, name: String) -> SeasonalRoundingRequest {
        return SeasonalRoundingRequest(
            code: code,
            name: name,
            active: false,
            unit: "",
            weight: 0.0,
            source: "",
            maximum: 0.0,
            segment: "",
            ward: "",
            graceDays: 0,
            status: SeasonalRoundingRequestStatus.created
        )
    }
}
