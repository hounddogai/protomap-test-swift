import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal courier claim is in its life cycle.
    enum SeasonalCourierClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a seasonal courier claim and its current status.
    final class SeasonalCourierClaim {
        var code: String
        var title: String
        var ratio: Double
        var expiresAt: Int
        var startsAt: Int
        var allergy: String
        var score: Double
        var dosageMg: Double
        var payer: String
        var status: SeasonalCourierClaimStatus

        init(code: String, title: String, ratio: Double, expiresAt: Int, startsAt: Int, allergy: String, score: Double, dosageMg: Double, payer: String, status: SeasonalCourierClaimStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.allergy = allergy
            self.score = score
            self.dosageMg = dosageMg
            self.payer = payer
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

        func canMoveTo(_ next: SeasonalCourierClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalCourierClaimStatus.approved
            case .approved:
                return next == SeasonalCourierClaimStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalCourierClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal courier claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCourierClaim {
            return SeasonalCourierClaim(
                code: code,
                title: title,
                ratio: ratio,
                expiresAt: expiresAt,
                startsAt: startsAt,
                allergy: allergy,
                score: score,
                dosageMg: dosageMg,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal courier claim in status proposed.
    static func newSeasonalCourierClaim(_ code: String, title: String) -> SeasonalCourierClaim {
        return SeasonalCourierClaim(
            code: code,
            title: title,
            ratio: 0.0,
            expiresAt: 0,
            startsAt: 0,
            allergy: "",
            score: 0.0,
            dosageMg: 0.0,
            payer: "",
            status: SeasonalCourierClaimStatus.proposed
        )
    }
}
