import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary transfer proposal is in its life cycle.
    enum PrimaryTransferProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary transfer proposal, with what the planners need to act on it.
    final class PrimaryTransferProposal {
        var code: String
        var name: String
        var diagnosisCode: String
        var source: String
        var locale: String
        var batchSize: Int
        var bed: String
        var status: PrimaryTransferProposalStatus

        init(code: String, name: String, diagnosisCode: String, source: String, locale: String, batchSize: Int, bed: String, status: PrimaryTransferProposalStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.locale = locale
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PrimaryTransferProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryTransferProposalStatus.approved
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

        func moveTo(_ next: PrimaryTransferProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary transfer proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary transfer proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> PrimaryTransferProposal {
            return PrimaryTransferProposal(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                source: source,
                locale: locale,
                batchSize: batchSize,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary transfer proposal in status proposed.
    static func newPrimaryTransferProposal(_ code: String, name: String) -> PrimaryTransferProposal {
        return PrimaryTransferProposal(
            code: code,
            name: name,
            diagnosisCode: "",
            source: "",
            locale: "",
            batchSize: 0,
            bed: "",
            status: PrimaryTransferProposalStatus.proposed
        )
    }
}
