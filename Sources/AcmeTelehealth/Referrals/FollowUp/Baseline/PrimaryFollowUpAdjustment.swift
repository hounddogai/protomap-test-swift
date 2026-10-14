import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary follow up adjustment is in its life cycle.
    enum PrimaryFollowUpAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary follow up adjustment, with what the planners need to act on it.
    final class PrimaryFollowUpAdjustment {
        var code: String
        var label: String
        var allergy: String
        var capacity: Int
        var priority: Int
        var encounterID: String
        var sequence: Int
        var contactEmail: String
        var quantity: Int
        var notes: String
        var status: PrimaryFollowUpAdjustmentStatus

        init(code: String, label: String, allergy: String, capacity: Int, priority: Int, encounterID: String, sequence: Int, contactEmail: String, quantity: Int, notes: String, status: PrimaryFollowUpAdjustmentStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.capacity = capacity
            self.priority = priority
            self.encounterID = encounterID
            self.sequence = sequence
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.notes = notes
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

        func canMoveTo(_ next: PrimaryFollowUpAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PrimaryFollowUpAdjustmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryFollowUpAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary follow up adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary follow up adjustment") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(quantity) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFollowUpAdjustment {
            return PrimaryFollowUpAdjustment(
                code: code,
                label: label,
                allergy: allergy,
                capacity: capacity,
                priority: priority,
                encounterID: encounterID,
                sequence: sequence,
                contactEmail: contactEmail,
                quantity: quantity,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary follow up adjustment in status requested.
    static func newPrimaryFollowUpAdjustment(_ code: String, label: String) -> PrimaryFollowUpAdjustment {
        return PrimaryFollowUpAdjustment(
            code: code,
            label: label,
            allergy: "",
            capacity: 0,
            priority: 0,
            encounterID: "",
            sequence: 0,
            contactEmail: "",
            quantity: 0,
            notes: "",
            status: PrimaryFollowUpAdjustmentStatus.requested
        )
    }
}
