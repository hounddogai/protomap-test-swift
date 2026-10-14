import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot policy is in its life cycle.
    enum SlotPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A slot policy as the slot team keeps it.
    final class SlotPolicy {
        var code: String
        var title: String
        var discount: Double
        var region: String
        var ceiling: Double
        var status: SlotPolicyStatus

        init(code: String, title: String, discount: Double, region: String, ceiling: Double, status: SlotPolicyStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.region = region
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SlotPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SlotPolicyStatus.reopened || next == SlotPolicyStatus.archived
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

        func moveTo(_ next: SlotPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((ceiling + discount) * 100).rounded() / 100
        }

        func copyValue() -> SlotPolicy {
            return SlotPolicy(
                code: code,
                title: title,
                discount: discount,
                region: region,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a slot policy in status open.
    static func newSlotPolicy(_ code: String, title: String) -> SlotPolicy {
        return SlotPolicy(
            code: code,
            title: title,
            discount: 0.0,
            region: "",
            ceiling: 0.0,
            status: SlotPolicyStatus.`open`
        )
    }
}
