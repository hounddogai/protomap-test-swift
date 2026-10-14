import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered modality forecast is in its life cycle.
    enum TieredModalityForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered modality forecast and its current status.
    final class TieredModalityForecast {
        var code: String
        var title: String
        var visible: Bool
        var archived: Bool
        var bed: String
        var specialty: String
        var margin: Double
        var status: TieredModalityForecastStatus

        init(code: String, title: String, visible: Bool, archived: Bool, bed: String, specialty: String, margin: Double, status: TieredModalityForecastStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.archived = archived
            self.bed = bed
            self.specialty = specialty
            self.margin = margin
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

        func canMoveTo(_ next: TieredModalityForecastStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredModalityForecastStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: TieredModalityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered modality forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> TieredModalityForecast {
            return TieredModalityForecast(
                code: code,
                title: title,
                visible: visible,
                archived: archived,
                bed: bed,
                specialty: specialty,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered modality forecast in status requested.
    static func newTieredModalityForecast(_ code: String, title: String) -> TieredModalityForecast {
        return TieredModalityForecast(
            code: code,
            title: title,
            visible: false,
            archived: false,
            bed: "",
            specialty: "",
            margin: 0.0,
            status: TieredModalityForecastStatus.requested
        )
    }
}
