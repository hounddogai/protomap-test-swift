import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal risk score preference is in its life cycle.
    enum SeasonalRiskScorePreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal risk score preference. Its code is unique within a tenant.
    final class SeasonalRiskScorePreference {
        var code: String
        var title: String
        var updatedAt: Int
        var threshold: Double
        var clinicianID: String
        var score: Double
        var timezone: String
        var status: SeasonalRiskScorePreferenceStatus

        init(code: String, title: String, updatedAt: Int, threshold: Double, clinicianID: String, score: Double, timezone: String, status: SeasonalRiskScorePreferenceStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.clinicianID = clinicianID
            self.score = score
            self.timezone = timezone
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

        func canMoveTo(_ next: SeasonalRiskScorePreferenceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: SeasonalRiskScorePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal risk score preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal risk score preference") \(code)"
        }

        func projectedTotal() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRiskScorePreference {
            return SeasonalRiskScorePreference(
                code: code,
                title: title,
                updatedAt: updatedAt,
                threshold: threshold,
                clinicianID: clinicianID,
                score: score,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal risk score preference in status created.
    static func newSeasonalRiskScorePreference(_ code: String, title: String) -> SeasonalRiskScorePreference {
        return SeasonalRiskScorePreference(
            code: code,
            title: title,
            updatedAt: 0,
            threshold: 0.0,
            clinicianID: "",
            score: 0.0,
            timezone: "",
            status: SeasonalRiskScorePreferenceStatus.created
        )
    }
}
