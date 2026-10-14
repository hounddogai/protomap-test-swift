import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense policy is in its life cycle.
    enum DispensePolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A dispense policy as the dispense team keeps it.
    final class DispensePolicy {
        var code: String
        var label: String
        var budget: Double
        var contactEmail: String
        var approved: Bool
        var archived: Bool
        var payer: String
        var sequence: Int
        var status: DispensePolicyStatus

        init(code: String, label: String, budget: Double, contactEmail: String, approved: Bool, archived: Bool, payer: String, sequence: Int, status: DispensePolicyStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.contactEmail = contactEmail
            self.approved = approved
            self.archived = archived
            self.payer = payer
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispensePolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == DispensePolicyStatus.ready || next == DispensePolicyStatus.draining
            case .warming:
                return next == DispensePolicyStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DispensePolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispensePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return (budget * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DispensePolicy {
            return DispensePolicy(
                code: code,
                label: label,
                budget: budget,
                contactEmail: contactEmail,
                approved: approved,
                archived: archived,
                payer: payer,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a dispense policy in status idle.
    static func newDispensePolicy(_ code: String, label: String) -> DispensePolicy {
        return DispensePolicy(
            code: code,
            label: label,
            budget: 0.0,
            contactEmail: "",
            approved: false,
            archived: false,
            payer: "",
            sequence: 0,
            status: DispensePolicyStatus.idle
        )
    }
}
