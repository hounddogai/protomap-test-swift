import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board proposal is in its life cycle.
    enum BedBoardProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A bed board proposal as the bed board team keeps it.
    final class BedBoardProposal {
        var code: String
        var label: String
        var revision: Int
        var region: String
        var discount: Double
        var timezone: String
        var payer: String
        var threshold: Double
        var checksum: String
        var status: BedBoardProposalStatus

        init(code: String, label: String, revision: Int, region: String, discount: Double, timezone: String, payer: String, threshold: Double, checksum: String, status: BedBoardProposalStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.region = region
            self.discount = discount
            self.timezone = timezone
            self.payer = payer
            self.threshold = threshold
            self.checksum = checksum
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

        func canMoveTo(_ next: BedBoardProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
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
                return next == BedBoardProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((threshold + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardProposal {
            return BedBoardProposal(
                code: code,
                label: label,
                revision: revision,
                region: region,
                discount: discount,
                timezone: timezone,
                payer: payer,
                threshold: threshold,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board proposal in status requested.
    static func newBedBoardProposal(_ code: String, label: String) -> BedBoardProposal {
        return BedBoardProposal(
            code: code,
            label: label,
            revision: 0,
            region: "",
            discount: 0.0,
            timezone: "",
            payer: "",
            threshold: 0.0,
            checksum: "",
            status: BedBoardProposalStatus.requested
        )
    }
}
