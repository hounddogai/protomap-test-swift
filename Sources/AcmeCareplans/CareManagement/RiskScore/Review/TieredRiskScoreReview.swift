import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered risk score review is in its life cycle.
    enum TieredRiskScoreReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered risk score review and its current status.
    final class TieredRiskScoreReview {
        var code: String
        var title: String
        var unit: String
        var margin: Double
        var archived: Bool
        var score: Double
        var status: TieredRiskScoreReviewStatus

        init(code: String, title: String, unit: String, margin: Double, archived: Bool, score: Double, status: TieredRiskScoreReviewStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.margin = margin
            self.archived = archived
            self.score = score
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

        func canMoveTo(_ next: TieredRiskScoreReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredRiskScoreReviewStatus.granted || next == TieredRiskScoreReviewStatus.revoked
            case .granted:
                return next == TieredRiskScoreReviewStatus.revoked || next == TieredRiskScoreReviewStatus.expired
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

        func moveTo(_ next: TieredRiskScoreReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered risk score review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (score * margin * 100).rounded() / 100
        }

        func copyValue() -> TieredRiskScoreReview {
            return TieredRiskScoreReview(
                code: code,
                title: title,
                unit: unit,
                margin: margin,
                archived: archived,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered risk score review in status requested.
    static func newTieredRiskScoreReview(_ code: String, title: String) -> TieredRiskScoreReview {
        return TieredRiskScoreReview(
            code: code,
            title: title,
            unit: "",
            margin: 0.0,
            archived: false,
            score: 0.0,
            status: TieredRiskScoreReviewStatus.requested
        )
    }
}
