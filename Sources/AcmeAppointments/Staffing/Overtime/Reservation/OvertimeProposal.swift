import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime proposal is in its life cycle.
    enum OvertimeProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime proposal. Its code is unique within a tenant.
    final class OvertimeProposal {
        var code: String
        var name: String
        var payer: String
        var limit: Int
        var batchSize: Int
        var ownerID: String
        var bed: String
        var status: OvertimeProposalStatus

        init(code: String, name: String, payer: String, limit: Int, batchSize: Int, ownerID: String, bed: String, status: OvertimeProposalStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.limit = limit
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.bed = bed
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

        func canMoveTo(_ next: OvertimeProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == OvertimeProposalStatus.rejected || next == OvertimeProposalStatus.withdrawn
            case .rejected:
                return next == OvertimeProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime proposal") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(batchSize) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeProposal {
            return OvertimeProposal(
                code: code,
                name: name,
                payer: payer,
                limit: limit,
                batchSize: batchSize,
                ownerID: ownerID,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a overtime proposal in status proposed.
    static func newOvertimeProposal(_ code: String, name: String) -> OvertimeProposal {
        return OvertimeProposal(
            code: code,
            name: name,
            payer: "",
            limit: 0,
            batchSize: 0,
            ownerID: "",
            bed: "",
            status: OvertimeProposalStatus.proposed
        )
    }
}
