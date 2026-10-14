import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global remittance assignment is in its life cycle.
    enum GlobalRemittanceAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a global remittance assignment and its current status.
    final class GlobalRemittanceAssignment {
        var code: String
        var label: String
        var discount: Double
        var summary: String
        var refills: Int
        var ownerID: String
        var quantity: Int
        var cost: Double
        var weight: Double
        var visible: Bool
        var status: GlobalRemittanceAssignmentStatus

        init(code: String, label: String, discount: Double, summary: String, refills: Int, ownerID: String, quantity: Int, cost: Double, weight: Double, visible: Bool, status: GlobalRemittanceAssignmentStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.summary = summary
            self.refills = refills
            self.ownerID = ownerID
            self.quantity = quantity
            self.cost = cost
            self.weight = weight
            self.visible = visible
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

        func canMoveTo(_ next: GlobalRemittanceAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalRemittanceAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global remittance assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(refills) + discount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRemittanceAssignment {
            return GlobalRemittanceAssignment(
                code: code,
                label: label,
                discount: discount,
                summary: summary,
                refills: refills,
                ownerID: ownerID,
                quantity: quantity,
                cost: cost,
                weight: weight,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global remittance assignment in status proposed.
    static func newGlobalRemittanceAssignment(_ code: String, label: String) -> GlobalRemittanceAssignment {
        return GlobalRemittanceAssignment(
            code: code,
            label: label,
            discount: 0.0,
            summary: "",
            refills: 0,
            ownerID: "",
            quantity: 0,
            cost: 0.0,
            weight: 0.0,
            visible: false,
            status: GlobalRemittanceAssignmentStatus.proposed
        )
    }
}
