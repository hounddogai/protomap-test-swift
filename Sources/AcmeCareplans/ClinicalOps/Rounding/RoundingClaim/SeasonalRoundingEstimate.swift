import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding estimate is in its life cycle.
    enum SeasonalRoundingEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal rounding estimate, with what the planners need to act on it.
    final class SeasonalRoundingEstimate {
        var code: String
        var name: String
        var diagnosisCode: String
        var timezone: String
        var version: Int
        var durationMinutes: Int
        var expiresAt: Int
        var source: String
        var status: SeasonalRoundingEstimateStatus

        init(code: String, name: String, diagnosisCode: String, timezone: String, version: Int, durationMinutes: Int, expiresAt: Int, source: String, status: SeasonalRoundingEstimateStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.version = version
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.source = source
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

        func canMoveTo(_ next: SeasonalRoundingEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalRoundingEstimateStatus.revoked
            case .granted:
                return next == SeasonalRoundingEstimateStatus.revoked || next == SeasonalRoundingEstimateStatus.expired
            case .revoked:
                return next == SeasonalRoundingEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRoundingEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(expiresAt) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRoundingEstimate {
            return SeasonalRoundingEstimate(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                version: version,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal rounding estimate in status requested.
    static func newSeasonalRoundingEstimate(_ code: String, name: String) -> SeasonalRoundingEstimate {
        return SeasonalRoundingEstimate(
            code: code,
            name: name,
            diagnosisCode: "",
            timezone: "",
            version: 0,
            durationMinutes: 0,
            expiresAt: 0,
            source: "",
            status: SeasonalRoundingEstimateStatus.requested
        )
    }
}
