import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up target is in its life cycle.
    enum FollowUpTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a follow up target and its current status.
    final class FollowUpTarget {
        var code: String
        var name: String
        var weight: Double
        var clinicianID: String
        var maximum: Double
        var status: FollowUpTargetStatus

        init(code: String, name: String, weight: Double, clinicianID: String, maximum: Double, status: FollowUpTargetStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.clinicianID = clinicianID
            self.maximum = maximum
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

        func canMoveTo(_ next: FollowUpTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FollowUpTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("follow up target") \(code)"
        }

        func netVolume() -> Double {
            return (weight * maximum * 100).rounded() / 100
        }

        func copyValue() -> FollowUpTarget {
            return FollowUpTarget(
                code: code,
                name: name,
                weight: weight,
                clinicianID: clinicianID,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up target in status proposed.
    static func newFollowUpTarget(_ code: String, name: String) -> FollowUpTarget {
        return FollowUpTarget(
            code: code,
            name: name,
            weight: 0.0,
            clinicianID: "",
            maximum: 0.0,
            status: FollowUpTargetStatus.proposed
        )
    }
}
