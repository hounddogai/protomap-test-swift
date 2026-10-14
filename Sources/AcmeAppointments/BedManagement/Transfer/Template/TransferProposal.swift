import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer proposal is in its life cycle.
    enum TransferProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A transfer proposal as the transfer team keeps it.
    final class TransferProposal {
        var code: String
        var label: String
        var ratio: Double
        var source: String
        var specialty: String
        var ward: String
        var floorValue: Double
        var acuity: Int
        var budget: Double
        var checksum: String
        var status: TransferProposalStatus

        init(code: String, label: String, ratio: Double, source: String, specialty: String, ward: String, floorValue: Double, acuity: Int, budget: Double, checksum: String, status: TransferProposalStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.source = source
            self.specialty = specialty
            self.ward = ward
            self.floorValue = floorValue
            self.acuity = acuity
            self.budget = budget
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

        func canMoveTo(_ next: TransferProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == TransferProposalStatus.granted || next == TransferProposalStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TransferProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(acuity) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> TransferProposal {
            return TransferProposal(
                code: code,
                label: label,
                ratio: ratio,
                source: source,
                specialty: specialty,
                ward: ward,
                floorValue: floorValue,
                acuity: acuity,
                budget: budget,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a transfer proposal in status requested.
    static func newTransferProposal(_ code: String, label: String) -> TransferProposal {
        return TransferProposal(
            code: code,
            label: label,
            ratio: 0.0,
            source: "",
            specialty: "",
            ward: "",
            floorValue: 0.0,
            acuity: 0,
            budget: 0.0,
            checksum: "",
            status: TransferProposalStatus.requested
        )
    }
}
