import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped credential milestone is in its life cycle.
    enum CappedCredentialMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped credential milestone and its current status.
    final class CappedCredentialMilestone {
        var code: String
        var title: String
        var channel: String
        var retries: Int
        var visible: Bool
        var discount: Double
        var payer: String
        var checksum: String
        var quantity: Int
        var status: CappedCredentialMilestoneStatus

        init(code: String, title: String, channel: String, retries: Int, visible: Bool, discount: Double, payer: String, checksum: String, quantity: Int, status: CappedCredentialMilestoneStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.retries = retries
            self.visible = visible
            self.discount = discount
            self.payer = payer
            self.checksum = checksum
            self.quantity = quantity
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

        func canMoveTo(_ next: CappedCredentialMilestoneStatus) -> Bool {
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
                return next == CappedCredentialMilestoneStatus.resolved
            case .resolved:
                return next == CappedCredentialMilestoneStatus.archived
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

        func moveTo(_ next: CappedCredentialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped credential milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped credential milestone") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(retries) - discount) * 100).rounded() / 100
        }

        func copyValue() -> CappedCredentialMilestone {
            return CappedCredentialMilestone(
                code: code,
                title: title,
                channel: channel,
                retries: retries,
                visible: visible,
                discount: discount,
                payer: payer,
                checksum: checksum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped credential milestone in status open.
    static func newCappedCredentialMilestone(_ code: String, title: String) -> CappedCredentialMilestone {
        return CappedCredentialMilestone(
            code: code,
            title: title,
            channel: "",
            retries: 0,
            visible: false,
            discount: 0.0,
            payer: "",
            checksum: "",
            quantity: 0,
            status: CappedCredentialMilestoneStatus.`open`
        )
    }
}
