import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling remittance proposal is in its life cycle.
    enum RollingRemittanceProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling remittance proposal and its current status.
    final class RollingRemittanceProposal {
        var code: String
        var title: String
        var minimum: Double
        var limit: Int
        var patientRef: String
        var unit: String
        var refills: Int
        var encounterID: String
        var notes: String
        var country: String
        var pinned: Bool
        var status: RollingRemittanceProposalStatus

        init(code: String, title: String, minimum: Double, limit: Int, patientRef: String, unit: String, refills: Int, encounterID: String, notes: String, country: String, pinned: Bool, status: RollingRemittanceProposalStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.limit = limit
            self.patientRef = patientRef
            self.unit = unit
            self.refills = refills
            self.encounterID = encounterID
            self.notes = notes
            self.country = country
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingRemittanceProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingRemittanceProposalStatus.inProgress || next == RollingRemittanceProposalStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RollingRemittanceProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling remittance proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(refills) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RollingRemittanceProposal {
            return RollingRemittanceProposal(
                code: code,
                title: title,
                minimum: minimum,
                limit: limit,
                patientRef: patientRef,
                unit: unit,
                refills: refills,
                encounterID: encounterID,
                notes: notes,
                country: country,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling remittance proposal in status planned.
    static func newRollingRemittanceProposal(_ code: String, title: String) -> RollingRemittanceProposal {
        return RollingRemittanceProposal(
            code: code,
            title: title,
            minimum: 0.0,
            limit: 0,
            patientRef: "",
            unit: "",
            refills: 0,
            encounterID: "",
            notes: "",
            country: "",
            pinned: false,
            status: RollingRemittanceProposalStatus.planned
        )
    }
}
