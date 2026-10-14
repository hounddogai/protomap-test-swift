import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score mapping is in its life cycle.
    enum RiskScoreMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A risk score mapping as the risk score team keeps it.
    final class RiskScoreMapping {
        var code: String
        var name: String
        var rate: Double
        var pinned: Bool
        var description: String
        var status: RiskScoreMappingStatus

        init(code: String, name: String, rate: Double, pinned: Bool, description: String, status: RiskScoreMappingStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.pinned = pinned
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == RiskScoreMappingStatus.scheduled
            case .scheduled:
                return next == RiskScoreMappingStatus.inProgress
            case .inProgress:
                return next == RiskScoreMappingStatus.completed
            case .completed:
                return next == RiskScoreMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> RiskScoreMapping {
            return RiskScoreMapping(
                code: code,
                name: name,
                rate: rate,
                pinned: pinned,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score mapping in status planned.
    static func newRiskScoreMapping(_ code: String, name: String) -> RiskScoreMapping {
        return RiskScoreMapping(
            code: code,
            name: name,
            rate: 0.0,
            pinned: false,
            description: "",
            status: RiskScoreMappingStatus.planned
        )
    }
}
