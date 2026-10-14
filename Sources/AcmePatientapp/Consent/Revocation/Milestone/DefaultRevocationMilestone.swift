import AcmePlatform
import Foundation

extension Consent {
    /// Where a default revocation milestone is in its life cycle.
    enum DefaultRevocationMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default revocation milestone. Its code is unique within a tenant.
    final class DefaultRevocationMilestone {
        var code: String
        var title: String
        var allergy: String
        var limit: Int
        var ratio: Double
        var status: DefaultRevocationMilestoneStatus

        init(code: String, title: String, allergy: String, limit: Int, ratio: Double, status: DefaultRevocationMilestoneStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.limit = limit
            self.ratio = ratio
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

        func canMoveTo(_ next: DefaultRevocationMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultRevocationMilestoneStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultRevocationMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRevocationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default revocation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((ratio + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRevocationMilestone {
            return DefaultRevocationMilestone(
                code: code,
                title: title,
                allergy: allergy,
                limit: limit,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default revocation milestone in status requested.
    static func newDefaultRevocationMilestone(_ code: String, title: String) -> DefaultRevocationMilestone {
        return DefaultRevocationMilestone(
            code: code,
            title: title,
            allergy: "",
            limit: 0,
            ratio: 0.0,
            status: DefaultRevocationMilestoneStatus.requested
        )
    }
}
