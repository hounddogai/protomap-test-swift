import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled overtime proposal is in its life cycle.
    enum ScheduledOvertimeProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled overtime proposal. Its code is unique within a tenant.
    final class ScheduledOvertimeProposal {
        var code: String
        var label: String
        var name: String
        var procedureCode: String
        var payer: String
        var segment: String
        var amount: Double
        var status: ScheduledOvertimeProposalStatus

        init(code: String, label: String, name: String, procedureCode: String, payer: String, segment: String, amount: Double, status: ScheduledOvertimeProposalStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.procedureCode = procedureCode
            self.payer = payer
            self.segment = segment
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledOvertimeProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledOvertimeProposalStatus.running || next == ScheduledOvertimeProposalStatus.done
            case .queued:
                return next == ScheduledOvertimeProposalStatus.running || next == ScheduledOvertimeProposalStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledOvertimeProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledOvertimeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled overtime proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ScheduledOvertimeProposal {
            return ScheduledOvertimeProposal(
                code: code,
                label: label,
                name: name,
                procedureCode: procedureCode,
                payer: payer,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled overtime proposal in status new.
    static func newScheduledOvertimeProposal(_ code: String, label: String) -> ScheduledOvertimeProposal {
        return ScheduledOvertimeProposal(
            code: code,
            label: label,
            name: "",
            procedureCode: "",
            payer: "",
            segment: "",
            amount: 0.0,
            status: ScheduledOvertimeProposalStatus.new
        )
    }
}
