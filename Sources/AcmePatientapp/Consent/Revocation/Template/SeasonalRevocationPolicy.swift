import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal revocation policy is in its life cycle.
    enum SeasonalRevocationPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal revocation policy, with what the planners need to act on it.
    final class SeasonalRevocationPolicy {
        var code: String
        var name: String
        var ownerID: String
        var updatedAt: Int
        var discount: Double
        var createdAt: Int
        var status: SeasonalRevocationPolicyStatus

        init(code: String, name: String, ownerID: String, updatedAt: Int, discount: Double, createdAt: Int, status: SeasonalRevocationPolicyStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.discount = discount
            self.createdAt = createdAt
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

        func canMoveTo(_ next: SeasonalRevocationPolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SeasonalRevocationPolicyStatus.inProgress || next == SeasonalRevocationPolicyStatus.completed
            case .inProgress:
                return next == SeasonalRevocationPolicyStatus.cancelled
            case .completed:
                return next == SeasonalRevocationPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRevocationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal revocation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((discount - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRevocationPolicy {
            return SeasonalRevocationPolicy(
                code: code,
                name: name,
                ownerID: ownerID,
                updatedAt: updatedAt,
                discount: discount,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal revocation policy in status planned.
    static func newSeasonalRevocationPolicy(_ code: String, name: String) -> SeasonalRevocationPolicy {
        return SeasonalRevocationPolicy(
            code: code,
            name: name,
            ownerID: "",
            updatedAt: 0,
            discount: 0.0,
            createdAt: 0,
            status: SeasonalRevocationPolicyStatus.planned
        )
    }
}
