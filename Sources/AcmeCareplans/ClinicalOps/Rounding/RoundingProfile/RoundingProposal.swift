import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding proposal is in its life cycle.
    enum RoundingProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a rounding proposal and its current status.
    final class RoundingProposal {
        var code: String
        var name: String
        var sequence: Int
        var summary: String
        var pinned: Bool
        var currency: String
        var endsAt: Int
        var status: RoundingProposalStatus

        init(code: String, name: String, sequence: Int, summary: String, pinned: Bool, currency: String, endsAt: Int, status: RoundingProposalStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.summary = summary
            self.pinned = pinned
            self.currency = currency
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RoundingProposalStatus.revoked || next == RoundingProposalStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RoundingProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingProposal {
            return RoundingProposal(
                code: code,
                name: name,
                sequence: sequence,
                summary: summary,
                pinned: pinned,
                currency: currency,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding proposal in status requested.
    static func newRoundingProposal(_ code: String, name: String) -> RoundingProposal {
        return RoundingProposal(
            code: code,
            name: name,
            sequence: 0,
            summary: "",
            pinned: false,
            currency: "",
            endsAt: 0,
            status: RoundingProposalStatus.requested
        )
    }
}
