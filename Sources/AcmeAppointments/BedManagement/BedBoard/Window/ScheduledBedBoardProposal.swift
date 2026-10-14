import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled bed board proposal is in its life cycle.
    enum ScheduledBedBoardProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a scheduled bed board proposal and its current status.
    final class ScheduledBedBoardProposal {
        var code: String
        var label: String
        var acuity: Int
        var summary: String
        var checksum: String
        var cost: Double
        var ownerID: String
        var dosageMg: Double
        var floorValue: Double
        var patientRef: String
        var pinned: Bool
        var status: ScheduledBedBoardProposalStatus

        init(code: String, label: String, acuity: Int, summary: String, checksum: String, cost: Double, ownerID: String, dosageMg: Double, floorValue: Double, patientRef: String, pinned: Bool, status: ScheduledBedBoardProposalStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.summary = summary
            self.checksum = checksum
            self.cost = cost
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.patientRef = patientRef
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledBedBoardProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledBedBoardProposalStatus.validated || next == ScheduledBedBoardProposalStatus.published
            case .validated:
                return next == ScheduledBedBoardProposalStatus.published
            case .published:
                return next == ScheduledBedBoardProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledBedBoardProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled bed board proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((dosageMg + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledBedBoardProposal {
            return ScheduledBedBoardProposal(
                code: code,
                label: label,
                acuity: acuity,
                summary: summary,
                checksum: checksum,
                cost: cost,
                ownerID: ownerID,
                dosageMg: dosageMg,
                floorValue: floorValue,
                patientRef: patientRef,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled bed board proposal in status created.
    static func newScheduledBedBoardProposal(_ code: String, label: String) -> ScheduledBedBoardProposal {
        return ScheduledBedBoardProposal(
            code: code,
            label: label,
            acuity: 0,
            summary: "",
            checksum: "",
            cost: 0.0,
            ownerID: "",
            dosageMg: 0.0,
            floorValue: 0.0,
            patientRef: "",
            pinned: false,
            status: ScheduledBedBoardProposalStatus.created
        )
    }
}
