import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary credential allocation is in its life cycle.
    enum PrimaryCredentialAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary credential allocation, with what the planners need to act on it.
    final class PrimaryCredentialAllocation {
        var code: String
        var title: String
        var capacity: Int
        var encounterID: String
        var contactEmail: String
        var label: String
        var amount: Double
        var region: String
        var unit: String
        var status: PrimaryCredentialAllocationStatus

        init(code: String, title: String, capacity: Int, encounterID: String, contactEmail: String, label: String, amount: Double, region: String, unit: String, status: PrimaryCredentialAllocationStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.encounterID = encounterID
            self.contactEmail = contactEmail
            self.label = label
            self.amount = amount
            self.region = region
            self.unit = unit
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

        func canMoveTo(_ next: PrimaryCredentialAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryCredentialAllocationStatus.granted || next == PrimaryCredentialAllocationStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimaryCredentialAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCredentialAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary credential allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return ((amount - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCredentialAllocation {
            return PrimaryCredentialAllocation(
                code: code,
                title: title,
                capacity: capacity,
                encounterID: encounterID,
                contactEmail: contactEmail,
                label: label,
                amount: amount,
                region: region,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary credential allocation in status requested.
    static func newPrimaryCredentialAllocation(_ code: String, title: String) -> PrimaryCredentialAllocation {
        return PrimaryCredentialAllocation(
            code: code,
            title: title,
            capacity: 0,
            encounterID: "",
            contactEmail: "",
            label: "",
            amount: 0.0,
            region: "",
            unit: "",
            status: PrimaryCredentialAllocationStatus.requested
        )
    }
}
