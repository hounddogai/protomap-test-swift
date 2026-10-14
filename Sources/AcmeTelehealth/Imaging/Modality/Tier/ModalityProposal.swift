import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality proposal is in its life cycle.
    enum ModalityProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality proposal as the modality team keeps it.
    final class ModalityProposal {
        var code: String
        var name: String
        var clinicianID: String
        var unit: String
        var copay: Double
        var status: ModalityProposalStatus

        init(code: String, name: String, clinicianID: String, unit: String, copay: Double, status: ModalityProposalStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.unit = unit
            self.copay = copay
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

        func canMoveTo(_ next: ModalityProposalStatus) -> Bool {
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
                return next == ModalityProposalStatus.rejected
            case .rejected:
                return next == ModalityProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> ModalityProposal {
            return ModalityProposal(
                code: code,
                name: name,
                clinicianID: clinicianID,
                unit: unit,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality proposal in status proposed.
    static func newModalityProposal(_ code: String, name: String) -> ModalityProposal {
        return ModalityProposal(
            code: code,
            name: name,
            clinicianID: "",
            unit: "",
            copay: 0.0,
            status: ModalityProposalStatus.proposed
        )
    }
}
