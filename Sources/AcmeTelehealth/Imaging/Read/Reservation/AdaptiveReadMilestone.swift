import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive read milestone is in its life cycle.
    enum AdaptiveReadMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive read milestone. Its code is unique within a tenant.
    final class AdaptiveReadMilestone {
        var code: String
        var name: String
        var ownerID: String
        var encounterID: String
        var ceiling: Double
        var segment: String
        var category: String
        var bed: String
        var cost: Double
        var quantity: Int
        var status: AdaptiveReadMilestoneStatus

        init(code: String, name: String, ownerID: String, encounterID: String, ceiling: Double, segment: String, category: String, bed: String, cost: Double, quantity: Int, status: AdaptiveReadMilestoneStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.segment = segment
            self.category = category
            self.bed = bed
            self.cost = cost
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveReadMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveReadMilestoneStatus.rejected || next == AdaptiveReadMilestoneStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveReadMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveReadMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive read milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return (Double(quantity) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReadMilestone {
            return AdaptiveReadMilestone(
                code: code,
                name: name,
                ownerID: ownerID,
                encounterID: encounterID,
                ceiling: ceiling,
                segment: segment,
                category: category,
                bed: bed,
                cost: cost,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive read milestone in status proposed.
    static func newAdaptiveReadMilestone(_ code: String, name: String) -> AdaptiveReadMilestone {
        return AdaptiveReadMilestone(
            code: code,
            name: name,
            ownerID: "",
            encounterID: "",
            ceiling: 0.0,
            segment: "",
            category: "",
            bed: "",
            cost: 0.0,
            quantity: 0,
            status: AdaptiveReadMilestoneStatus.proposed
        )
    }
}
