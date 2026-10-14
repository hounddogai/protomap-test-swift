import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation draft is in its life cycle.
    enum RegionalIsolationDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional isolation draft and its current status.
    final class RegionalIsolationDraft {
        var code: String
        var name: String
        var clinicianID: String
        var priority: Int
        var createdAt: Int
        var margin: Double
        var amount: Double
        var dosageMg: Double
        var ownerID: String
        var contactEmail: String
        var ward: String
        var status: RegionalIsolationDraftStatus

        init(code: String, name: String, clinicianID: String, priority: Int, createdAt: Int, margin: Double, amount: Double, dosageMg: Double, ownerID: String, contactEmail: String, ward: String, status: RegionalIsolationDraftStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.priority = priority
            self.createdAt = createdAt
            self.margin = margin
            self.amount = amount
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.ward = ward
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

        func canMoveTo(_ next: RegionalIsolationDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalIsolationDraftStatus.approved
            case .approved:
                return next == RegionalIsolationDraftStatus.withdrawn
            case .rejected:
                return next == RegionalIsolationDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalIsolationDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return ((dosageMg + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalIsolationDraft {
            return RegionalIsolationDraft(
                code: code,
                name: name,
                clinicianID: clinicianID,
                priority: priority,
                createdAt: createdAt,
                margin: margin,
                amount: amount,
                dosageMg: dosageMg,
                ownerID: ownerID,
                contactEmail: contactEmail,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional isolation draft in status proposed.
    static func newRegionalIsolationDraft(_ code: String, name: String) -> RegionalIsolationDraft {
        return RegionalIsolationDraft(
            code: code,
            name: name,
            clinicianID: "",
            priority: 0,
            createdAt: 0,
            margin: 0.0,
            amount: 0.0,
            dosageMg: 0.0,
            ownerID: "",
            contactEmail: "",
            ward: "",
            status: RegionalIsolationDraftStatus.proposed
        )
    }
}
