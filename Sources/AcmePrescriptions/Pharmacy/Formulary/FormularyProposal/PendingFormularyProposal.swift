import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending formulary proposal is in its life cycle.
    enum PendingFormularyProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending formulary proposal. Its code is unique within a tenant.
    final class PendingFormularyProposal {
        var code: String
        var title: String
        var batchSize: Int
        var externalRef: String
        var reviewer: String
        var source: String
        var channel: String
        var status: PendingFormularyProposalStatus

        init(code: String, title: String, batchSize: Int, externalRef: String, reviewer: String, source: String, channel: String, status: PendingFormularyProposalStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.source = source
            self.channel = channel
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

        func canMoveTo(_ next: PendingFormularyProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingFormularyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending formulary proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> PendingFormularyProposal {
            return PendingFormularyProposal(
                code: code,
                title: title,
                batchSize: batchSize,
                externalRef: externalRef,
                reviewer: reviewer,
                source: source,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending formulary proposal in status requested.
    static func newPendingFormularyProposal(_ code: String, title: String) -> PendingFormularyProposal {
        return PendingFormularyProposal(
            code: code,
            title: title,
            batchSize: 0,
            externalRef: "",
            reviewer: "",
            source: "",
            channel: "",
            status: PendingFormularyProposalStatus.requested
        )
    }
}
