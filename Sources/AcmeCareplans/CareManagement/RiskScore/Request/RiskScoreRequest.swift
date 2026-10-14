import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score request is in its life cycle.
    enum RiskScoreRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One risk score request, with what the planners need to act on it.
    final class RiskScoreRequest {
        var code: String
        var title: String
        var allergy: String
        var encounterID: String
        var updatedAt: Int
        var maximum: Double
        var status: RiskScoreRequestStatus

        init(code: String, title: String, allergy: String, encounterID: String, updatedAt: Int, maximum: Double, status: RiskScoreRequestStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RiskScoreRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return (maximum * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreRequest {
            return RiskScoreRequest(
                code: code,
                title: title,
                allergy: allergy,
                encounterID: encounterID,
                updatedAt: updatedAt,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a risk score request in status new.
    static func newRiskScoreRequest(_ code: String, title: String) -> RiskScoreRequest {
        return RiskScoreRequest(
            code: code,
            title: title,
            allergy: "",
            encounterID: "",
            updatedAt: 0,
            maximum: 0.0,
            status: RiskScoreRequestStatus.new
        )
    }
}
