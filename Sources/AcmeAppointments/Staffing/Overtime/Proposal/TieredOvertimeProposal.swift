import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered overtime proposal is in its life cycle.
    enum TieredOvertimeProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered overtime proposal as the overtime team keeps it.
    final class TieredOvertimeProposal {
        var code: String
        var name: String
        var category: String
        var expiresAt: Int
        var ward: String
        var archived: Bool
        var specialty: String
        var unit: String
        var encounterID: String
        var status: TieredOvertimeProposalStatus

        init(code: String, name: String, category: String, expiresAt: Int, ward: String, archived: Bool, specialty: String, unit: String, encounterID: String, status: TieredOvertimeProposalStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.expiresAt = expiresAt
            self.ward = ward
            self.archived = archived
            self.specialty = specialty
            self.unit = unit
            self.encounterID = encounterID
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

        func canMoveTo(_ next: TieredOvertimeProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredOvertimeProposalStatus.revoked || next == TieredOvertimeProposalStatus.expired
            case .granted:
                return next == TieredOvertimeProposalStatus.revoked
            case .revoked:
                return next == TieredOvertimeProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOvertimeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered overtime proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered overtime proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> TieredOvertimeProposal {
            return TieredOvertimeProposal(
                code: code,
                name: name,
                category: category,
                expiresAt: expiresAt,
                ward: ward,
                archived: archived,
                specialty: specialty,
                unit: unit,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered overtime proposal in status requested.
    static func newTieredOvertimeProposal(_ code: String, name: String) -> TieredOvertimeProposal {
        return TieredOvertimeProposal(
            code: code,
            name: name,
            category: "",
            expiresAt: 0,
            ward: "",
            archived: false,
            specialty: "",
            unit: "",
            encounterID: "",
            status: TieredOvertimeProposalStatus.requested
        )
    }
}
