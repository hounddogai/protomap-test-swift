import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal risk score variance is in its life cycle.
    enum SeasonalRiskScoreVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal risk score variance. Its code is unique within a tenant.
    final class SeasonalRiskScoreVariance {
        var code: String
        var label: String
        var procedureCode: String
        var archived: Bool
        var retries: Int
        var externalRef: String
        var maximum: Double
        var country: String
        var score: Double
        var approved: Bool
        var version: Int
        var status: SeasonalRiskScoreVarianceStatus

        init(code: String, label: String, procedureCode: String, archived: Bool, retries: Int, externalRef: String, maximum: Double, country: String, score: Double, approved: Bool, version: Int, status: SeasonalRiskScoreVarianceStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.archived = archived
            self.retries = retries
            self.externalRef = externalRef
            self.maximum = maximum
            self.country = country
            self.score = score
            self.approved = approved
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalRiskScoreVarianceStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalRiskScoreVarianceStatus.ready
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: SeasonalRiskScoreVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal risk score variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("seasonal risk score variance") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(retries) + score) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRiskScoreVariance {
            return SeasonalRiskScoreVariance(
                code: code,
                label: label,
                procedureCode: procedureCode,
                archived: archived,
                retries: retries,
                externalRef: externalRef,
                maximum: maximum,
                country: country,
                score: score,
                approved: approved,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal risk score variance in status idle.
    static func newSeasonalRiskScoreVariance(_ code: String, label: String) -> SeasonalRiskScoreVariance {
        return SeasonalRiskScoreVariance(
            code: code,
            label: label,
            procedureCode: "",
            archived: false,
            retries: 0,
            externalRef: "",
            maximum: 0.0,
            country: "",
            score: 0.0,
            approved: false,
            version: 0,
            status: SeasonalRiskScoreVarianceStatus.idle
        )
    }
}
