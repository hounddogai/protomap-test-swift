import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered float pool plan is in its life cycle.
    enum TieredFloatPoolPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered float pool plan and its current status.
    final class TieredFloatPoolPlan {
        var code: String
        var label: String
        var capacity: Int
        var phone: String
        var externalRef: String
        var contactEmail: String
        var channel: String
        var status: TieredFloatPoolPlanStatus

        init(code: String, label: String, capacity: Int, phone: String, externalRef: String, contactEmail: String, channel: String, status: TieredFloatPoolPlanStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.phone = phone
            self.externalRef = externalRef
            self.contactEmail = contactEmail
            self.channel = channel
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

        func canMoveTo(_ next: TieredFloatPoolPlanStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredFloatPoolPlanStatus.reopened || next == TieredFloatPoolPlanStatus.archived
            case .resolved:
                return next == TieredFloatPoolPlanStatus.archived
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

        func moveTo(_ next: TieredFloatPoolPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered float pool plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> TieredFloatPoolPlan {
            return TieredFloatPoolPlan(
                code: code,
                label: label,
                capacity: capacity,
                phone: phone,
                externalRef: externalRef,
                contactEmail: contactEmail,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered float pool plan in status open.
    static func newTieredFloatPoolPlan(_ code: String, label: String) -> TieredFloatPoolPlan {
        return TieredFloatPoolPlan(
            code: code,
            label: label,
            capacity: 0,
            phone: "",
            externalRef: "",
            contactEmail: "",
            channel: "",
            status: TieredFloatPoolPlanStatus.`open`
        )
    }
}
