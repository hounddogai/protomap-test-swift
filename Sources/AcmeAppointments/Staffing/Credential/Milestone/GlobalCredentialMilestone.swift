import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential milestone is in its life cycle.
    enum GlobalCredentialMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global credential milestone as the credential team keeps it.
    final class GlobalCredentialMilestone {
        var code: String
        var title: String
        var name: String
        var retries: Int
        var pinned: Bool
        var priority: Int
        var allergy: String
        var segment: String
        var floorValue: Double
        var discount: Double
        var ratio: Double
        var status: GlobalCredentialMilestoneStatus

        init(code: String, title: String, name: String, retries: Int, pinned: Bool, priority: Int, allergy: String, segment: String, floorValue: Double, discount: Double, ratio: Double, status: GlobalCredentialMilestoneStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.retries = retries
            self.pinned = pinned
            self.priority = priority
            self.allergy = allergy
            self.segment = segment
            self.floorValue = floorValue
            self.discount = discount
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

        func canMoveTo(_ next: GlobalCredentialMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalCredentialMilestoneStatus.revoked
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

        func moveTo(_ next: GlobalCredentialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCredentialMilestone {
            return GlobalCredentialMilestone(
                code: code,
                title: title,
                name: name,
                retries: retries,
                pinned: pinned,
                priority: priority,
                allergy: allergy,
                segment: segment,
                floorValue: floorValue,
                discount: discount,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global credential milestone in status requested.
    static func newGlobalCredentialMilestone(_ code: String, title: String) -> GlobalCredentialMilestone {
        return GlobalCredentialMilestone(
            code: code,
            title: title,
            name: "",
            retries: 0,
            pinned: false,
            priority: 0,
            allergy: "",
            segment: "",
            floorValue: 0.0,
            discount: 0.0,
            ratio: 0.0,
            status: GlobalCredentialMilestoneStatus.requested
        )
    }
}
