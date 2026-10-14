import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score review is in its life cycle.
    enum RiskScoreReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A risk score review as the risk score team keeps it.
    final class RiskScoreReview {
        var code: String
        var name: String
        var unit: String
        var weight: Double
        var threshold: Double
        var floorValue: Double
        var encounterID: String
        var status: RiskScoreReviewStatus

        init(code: String, name: String, unit: String, weight: Double, threshold: Double, floorValue: Double, encounterID: String, status: RiskScoreReviewStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.weight = weight
            self.threshold = threshold
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RiskScoreReviewStatus.suspended || next == RiskScoreReviewStatus.closed
            case .suspended:
                return next == RiskScoreReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((floorValue + weight) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreReview {
            return RiskScoreReview(
                code: code,
                name: name,
                unit: unit,
                weight: weight,
                threshold: threshold,
                floorValue: floorValue,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score review in status draft.
    static func newRiskScoreReview(_ code: String, name: String) -> RiskScoreReview {
        return RiskScoreReview(
            code: code,
            name: name,
            unit: "",
            weight: 0.0,
            threshold: 0.0,
            floorValue: 0.0,
            encounterID: "",
            status: RiskScoreReviewStatus.draft
        )
    }
}
