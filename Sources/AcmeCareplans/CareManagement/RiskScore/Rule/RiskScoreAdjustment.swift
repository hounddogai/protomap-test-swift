import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score adjustment is in its life cycle.
    enum RiskScoreAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A risk score adjustment as the risk score team keeps it.
    final class RiskScoreAdjustment {
        var code: String
        var title: String
        var margin: Double
        var source: String
        var threshold: Double
        var encounterID: String
        var name: String
        var status: RiskScoreAdjustmentStatus

        init(code: String, title: String, margin: Double, source: String, threshold: Double, encounterID: String, name: String, status: RiskScoreAdjustmentStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.source = source
            self.threshold = threshold
            self.encounterID = encounterID
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RiskScoreAdjustmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedValue() -> Double {
            return ((threshold - margin) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreAdjustment {
            return RiskScoreAdjustment(
                code: code,
                title: title,
                margin: margin,
                source: source,
                threshold: threshold,
                encounterID: encounterID,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a risk score adjustment in status open.
    static func newRiskScoreAdjustment(_ code: String, title: String) -> RiskScoreAdjustment {
        return RiskScoreAdjustment(
            code: code,
            title: title,
            margin: 0.0,
            source: "",
            threshold: 0.0,
            encounterID: "",
            name: "",
            status: RiskScoreAdjustmentStatus.`open`
        )
    }
}
