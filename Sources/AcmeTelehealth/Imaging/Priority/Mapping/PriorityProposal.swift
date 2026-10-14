import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority proposal is in its life cycle.
    enum PriorityProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A priority proposal. Its code is unique within a tenant.
    final class PriorityProposal {
        var code: String
        var name: String
        var limit: Int
        var margin: Double
        var acuity: Int
        var status: PriorityProposalStatus

        init(code: String, name: String, limit: Int, margin: Double, acuity: Int, status: PriorityProposalStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.margin = margin
            self.acuity = acuity
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

        func canMoveTo(_ next: PriorityProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == PriorityProposalStatus.granted
            case .granted:
                return next == PriorityProposalStatus.revoked
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

        func moveTo(_ next: PriorityProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(acuity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityProposal {
            return PriorityProposal(
                code: code,
                name: name,
                limit: limit,
                margin: margin,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority proposal in status requested.
    static func newPriorityProposal(_ code: String, name: String) -> PriorityProposal {
        return PriorityProposal(
            code: code,
            name: name,
            limit: 0,
            margin: 0.0,
            acuity: 0,
            status: PriorityProposalStatus.requested
        )
    }
}
