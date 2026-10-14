import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility slot is in its life cycle.
    enum EligibilitySlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A eligibility slot. Its code is unique within a tenant.
    final class EligibilitySlot {
        var code: String
        var name: String
        var clinicianID: String
        var updatedAt: Int
        var endsAt: Int
        var ownerID: String
        var phone: String
        var encounterID: String
        var status: EligibilitySlotStatus

        init(code: String, name: String, clinicianID: String, updatedAt: Int, endsAt: Int, ownerID: String, phone: String, encounterID: String, status: EligibilitySlotStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.ownerID = ownerID
            self.phone = phone
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilitySlotStatus) -> Bool {
            switch status {
            case .`open`:
                return next == EligibilitySlotStatus.reopened || next == EligibilitySlotStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == EligibilitySlotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return (Double(updatedAt) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> EligibilitySlot {
            return EligibilitySlot(
                code: code,
                name: name,
                clinicianID: clinicianID,
                updatedAt: updatedAt,
                endsAt: endsAt,
                ownerID: ownerID,
                phone: phone,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility slot in status open.
    static func newEligibilitySlot(_ code: String, name: String) -> EligibilitySlot {
        return EligibilitySlot(
            code: code,
            name: name,
            clinicianID: "",
            updatedAt: 0,
            endsAt: 0,
            ownerID: "",
            phone: "",
            encounterID: "",
            status: EligibilitySlotStatus.`open`
        )
    }
}
