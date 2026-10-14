import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach proposal is in its life cycle.
    enum LenientOutreachProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient outreach proposal. Its code is unique within a tenant.
    final class LenientOutreachProposal {
        var code: String
        var label: String
        var revision: Int
        var budget: Double
        var externalRef: String
        var encounterID: String
        var approved: Bool
        var unit: String
        var endsAt: Int
        var amount: Double
        var status: LenientOutreachProposalStatus

        init(code: String, label: String, revision: Int, budget: Double, externalRef: String, encounterID: String, approved: Bool, unit: String, endsAt: Int, amount: Double, status: LenientOutreachProposalStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.budget = budget
            self.externalRef = externalRef
            self.encounterID = encounterID
            self.approved = approved
            self.unit = unit
            self.endsAt = endsAt
            self.amount = amount
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

        func canMoveTo(_ next: LenientOutreachProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LenientOutreachProposalStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientOutreachProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((budget + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachProposal {
            return LenientOutreachProposal(
                code: code,
                label: label,
                revision: revision,
                budget: budget,
                externalRef: externalRef,
                encounterID: encounterID,
                approved: approved,
                unit: unit,
                endsAt: endsAt,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient outreach proposal in status idle.
    static func newLenientOutreachProposal(_ code: String, label: String) -> LenientOutreachProposal {
        return LenientOutreachProposal(
            code: code,
            label: label,
            revision: 0,
            budget: 0.0,
            externalRef: "",
            encounterID: "",
            approved: false,
            unit: "",
            endsAt: 0,
            amount: 0.0,
            status: LenientOutreachProposalStatus.idle
        )
    }
}
