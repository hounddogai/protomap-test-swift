import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched denial milestone is in its life cycle.
    enum BatchedDenialMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched denial milestone. Its code is unique within a tenant.
    final class BatchedDenialMilestone {
        var code: String
        var name: String
        var quantity: Int
        var sequence: Int
        var timezone: String
        var locale: String
        var region: String
        var cost: Double
        var pinned: Bool
        var approved: Bool
        var status: BatchedDenialMilestoneStatus

        init(code: String, name: String, quantity: Int, sequence: Int, timezone: String, locale: String, region: String, cost: Double, pinned: Bool, approved: Bool, status: BatchedDenialMilestoneStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.sequence = sequence
            self.timezone = timezone
            self.locale = locale
            self.region = region
            self.cost = cost
            self.pinned = pinned
            self.approved = approved
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

        func canMoveTo(_ next: BatchedDenialMilestoneStatus) -> Bool {
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
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: BatchedDenialMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched denial milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched denial milestone") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(quantity) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDenialMilestone {
            return BatchedDenialMilestone(
                code: code,
                name: name,
                quantity: quantity,
                sequence: sequence,
                timezone: timezone,
                locale: locale,
                region: region,
                cost: cost,
                pinned: pinned,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched denial milestone in status open.
    static func newBatchedDenialMilestone(_ code: String, name: String) -> BatchedDenialMilestone {
        return BatchedDenialMilestone(
            code: code,
            name: name,
            quantity: 0,
            sequence: 0,
            timezone: "",
            locale: "",
            region: "",
            cost: 0.0,
            pinned: false,
            approved: false,
            status: BatchedDenialMilestoneStatus.`open`
        )
    }
}
