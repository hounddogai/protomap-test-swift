import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding score is in its life cycle.
    enum SeasonalRoundingScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One seasonal rounding score, with what the planners need to act on it.
    final class SeasonalRoundingScore {
        var code: String
        var label: String
        var refills: Int
        var clinicianID: String
        var ceiling: Double
        var ownerID: String
        var score: Double
        var expiresAt: Int
        var patientRef: String
        var endsAt: Int
        var region: String
        var status: SeasonalRoundingScoreStatus

        init(code: String, label: String, refills: Int, clinicianID: String, ceiling: Double, ownerID: String, score: Double, expiresAt: Int, patientRef: String, endsAt: Int, region: String, status: SeasonalRoundingScoreStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.score = score
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalRoundingScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SeasonalRoundingScoreStatus.rejected || next == SeasonalRoundingScoreStatus.withdrawn
            case .rejected:
                return next == SeasonalRoundingScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRoundingScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal rounding score") \(code)"
        }

        func netValue() -> Double {
            return ((Double(expiresAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRoundingScore {
            return SeasonalRoundingScore(
                code: code,
                label: label,
                refills: refills,
                clinicianID: clinicianID,
                ceiling: ceiling,
                ownerID: ownerID,
                score: score,
                expiresAt: expiresAt,
                patientRef: patientRef,
                endsAt: endsAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal rounding score in status proposed.
    static func newSeasonalRoundingScore(_ code: String, label: String) -> SeasonalRoundingScore {
        return SeasonalRoundingScore(
            code: code,
            label: label,
            refills: 0,
            clinicianID: "",
            ceiling: 0.0,
            ownerID: "",
            score: 0.0,
            expiresAt: 0,
            patientRef: "",
            endsAt: 0,
            region: "",
            status: SeasonalRoundingScoreStatus.proposed
        )
    }
}
