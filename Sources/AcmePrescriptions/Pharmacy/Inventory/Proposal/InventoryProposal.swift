import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory proposal is in its life cycle.
    enum InventoryProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a inventory proposal and its current status.
    final class InventoryProposal {
        var code: String
        var label: String
        var amount: Double
        var channel: String
        var visible: Bool
        var contactEmail: String
        var visitMinutes: Int
        var patientRef: String
        var status: InventoryProposalStatus

        init(code: String, label: String, amount: Double, channel: String, visible: Bool, contactEmail: String, visitMinutes: Int, patientRef: String, status: InventoryProposalStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.channel = channel
            self.visible = visible
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == InventoryProposalStatus.validated || next == InventoryProposalStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: InventoryProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((amount - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryProposal {
            return InventoryProposal(
                code: code,
                label: label,
                amount: amount,
                channel: channel,
                visible: visible,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a inventory proposal in status created.
    static func newInventoryProposal(_ code: String, label: String) -> InventoryProposal {
        return InventoryProposal(
            code: code,
            label: label,
            amount: 0.0,
            channel: "",
            visible: false,
            contactEmail: "",
            visitMinutes: 0,
            patientRef: "",
            status: InventoryProposalStatus.created
        )
    }
}
