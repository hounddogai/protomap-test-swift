import AcmePlatform
import Foundation

extension Consent {
    /// Where a default proxy proposal is in its life cycle.
    enum DefaultProxyProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default proxy proposal. Its code is unique within a tenant.
    final class DefaultProxyProposal {
        var code: String
        var label: String
        var amount: Double
        var procedureCode: String
        var specialty: String
        var reviewer: String
        var capacity: Int
        var status: DefaultProxyProposalStatus

        init(code: String, label: String, amount: Double, procedureCode: String, specialty: String, reviewer: String, capacity: Int, status: DefaultProxyProposalStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.reviewer = reviewer
            self.capacity = capacity
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

        func canMoveTo(_ next: DefaultProxyProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultProxyProposalStatus.draining || next == DefaultProxyProposalStatus.stopped
            case .draining:
                return next == DefaultProxyProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProxyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default proxy proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((amount - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProxyProposal {
            return DefaultProxyProposal(
                code: code,
                label: label,
                amount: amount,
                procedureCode: procedureCode,
                specialty: specialty,
                reviewer: reviewer,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default proxy proposal in status idle.
    static func newDefaultProxyProposal(_ code: String, label: String) -> DefaultProxyProposal {
        return DefaultProxyProposal(
            code: code,
            label: label,
            amount: 0.0,
            procedureCode: "",
            specialty: "",
            reviewer: "",
            capacity: 0,
            status: DefaultProxyProposalStatus.idle
        )
    }
}
