import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient overtime proposal is in its life cycle.
    enum LenientOvertimeProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient overtime proposal as the overtime team keeps it.
    final class LenientOvertimeProposal {
        var code: String
        var label: String
        var acuity: Int
        var attempts: Int
        var priority: Int
        var status: LenientOvertimeProposalStatus

        init(code: String, label: String, acuity: Int, attempts: Int, priority: Int, status: LenientOvertimeProposalStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.attempts = attempts
            self.priority = priority
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

        func canMoveTo(_ next: LenientOvertimeProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientOvertimeProposalStatus.reopened
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

        func moveTo(_ next: LenientOvertimeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient overtime proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(acuity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LenientOvertimeProposal {
            return LenientOvertimeProposal(
                code: code,
                label: label,
                acuity: acuity,
                attempts: attempts,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient overtime proposal in status open.
    static func newLenientOvertimeProposal(_ code: String, label: String) -> LenientOvertimeProposal {
        return LenientOvertimeProposal(
            code: code,
            label: label,
            acuity: 0,
            attempts: 0,
            priority: 0,
            status: LenientOvertimeProposalStatus.`open`
        )
    }
}
