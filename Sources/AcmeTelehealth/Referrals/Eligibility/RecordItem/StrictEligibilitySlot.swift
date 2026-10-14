import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict eligibility slot is in its life cycle.
    enum StrictEligibilitySlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a strict eligibility slot and its current status.
    final class StrictEligibilitySlot {
        var code: String
        var name: String
        var quantity: Int
        var encounterID: String
        var ownerID: String
        var patientRef: String
        var clinicianID: String
        var createdAt: Int
        var attempts: Int
        var retries: Int
        var status: StrictEligibilitySlotStatus

        init(code: String, name: String, quantity: Int, encounterID: String, ownerID: String, patientRef: String, clinicianID: String, createdAt: Int, attempts: Int, retries: Int, status: StrictEligibilitySlotStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.attempts = attempts
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictEligibilitySlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictEligibilitySlotStatus.active || next == StrictEligibilitySlotStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictEligibilitySlotStatus.suspended || next == StrictEligibilitySlotStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictEligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return (Double(createdAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> StrictEligibilitySlot {
            return StrictEligibilitySlot(
                code: code,
                name: name,
                quantity: quantity,
                encounterID: encounterID,
                ownerID: ownerID,
                patientRef: patientRef,
                clinicianID: clinicianID,
                createdAt: createdAt,
                attempts: attempts,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict eligibility slot in status draft.
    static func newStrictEligibilitySlot(_ code: String, name: String) -> StrictEligibilitySlot {
        return StrictEligibilitySlot(
            code: code,
            name: name,
            quantity: 0,
            encounterID: "",
            ownerID: "",
            patientRef: "",
            clinicianID: "",
            createdAt: 0,
            attempts: 0,
            retries: 0,
            status: StrictEligibilitySlotStatus.draft
        )
    }
}
