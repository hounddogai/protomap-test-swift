import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal accession forecast is in its life cycle.
    enum SeasonalAccessionForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal accession forecast. Its code is unique within a tenant.
    final class SeasonalAccessionForecast {
        var code: String
        var label: String
        var copay: Double
        var description: String
        var title: String
        var visitMinutes: Int
        var procedureCode: String
        var endsAt: Int
        var minimum: Double
        var encounterID: String
        var status: SeasonalAccessionForecastStatus

        init(code: String, label: String, copay: Double, description: String, title: String, visitMinutes: Int, procedureCode: String, endsAt: Int, minimum: Double, encounterID: String, status: SeasonalAccessionForecastStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.description = description
            self.title = title
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.minimum = minimum
            self.encounterID = encounterID
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

        func canMoveTo(_ next: SeasonalAccessionForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalAccessionForecastStatus.revoked || next == SeasonalAccessionForecastStatus.expired
            case .revoked:
                return next == SeasonalAccessionForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAccessionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal accession forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return ((copay + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAccessionForecast {
            return SeasonalAccessionForecast(
                code: code,
                label: label,
                copay: copay,
                description: description,
                title: title,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                endsAt: endsAt,
                minimum: minimum,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal accession forecast in status requested.
    static func newSeasonalAccessionForecast(_ code: String, label: String) -> SeasonalAccessionForecast {
        return SeasonalAccessionForecast(
            code: code,
            label: label,
            copay: 0.0,
            description: "",
            title: "",
            visitMinutes: 0,
            procedureCode: "",
            endsAt: 0,
            minimum: 0.0,
            encounterID: "",
            status: SeasonalAccessionForecastStatus.requested
        )
    }
}
