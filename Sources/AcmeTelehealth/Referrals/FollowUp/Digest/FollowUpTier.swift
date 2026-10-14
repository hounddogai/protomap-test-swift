import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up tier is in its life cycle.
    enum FollowUpTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a follow up tier and its current status.
    final class FollowUpTier {
        var code: String
        var label: String
        var acuity: Int
        var createdAt: Int
        var cost: Double
        var checksum: String
        var status: FollowUpTierStatus

        init(code: String, label: String, acuity: Int, createdAt: Int, cost: Double, checksum: String, status: FollowUpTierStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.createdAt = createdAt
            self.cost = cost
            self.checksum = checksum
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

        func canMoveTo(_ next: FollowUpTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FollowUpTierStatus.reopened || next == FollowUpTierStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FollowUpTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("follow up tier") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpTier {
            return FollowUpTier(
                code: code,
                label: label,
                acuity: acuity,
                createdAt: createdAt,
                cost: cost,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up tier in status open.
    static func newFollowUpTier(_ code: String, label: String) -> FollowUpTier {
        return FollowUpTier(
            code: code,
            label: label,
            acuity: 0,
            createdAt: 0,
            cost: 0.0,
            checksum: "",
            status: FollowUpTierStatus.`open`
        )
    }
}
