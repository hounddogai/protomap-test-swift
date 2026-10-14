import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial slot is in its life cycle.
    enum DenialSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One denial slot, with what the planners need to act on it.
    final class DenialSlot {
        var code: String
        var label: String
        var clinicianID: String
        var capacity: Int
        var notes: String
        var region: String
        var rate: Double
        var contactEmail: String
        var limit: Int
        var patientRef: String
        var status: DenialSlotStatus

        init(code: String, label: String, clinicianID: String, capacity: Int, notes: String, region: String, rate: Double, contactEmail: String, limit: Int, patientRef: String, status: DenialSlotStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.capacity = capacity
            self.notes = notes
            self.region = region
            self.rate = rate
            self.contactEmail = contactEmail
            self.limit = limit
            self.patientRef = patientRef
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

        func canMoveTo(_ next: DenialSlotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialSlotStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DenialSlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(capacity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DenialSlot {
            return DenialSlot(
                code: code,
                label: label,
                clinicianID: clinicianID,
                capacity: capacity,
                notes: notes,
                region: region,
                rate: rate,
                contactEmail: contactEmail,
                limit: limit,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a denial slot in status proposed.
    static func newDenialSlot(_ code: String, label: String) -> DenialSlot {
        return DenialSlot(
            code: code,
            label: label,
            clinicianID: "",
            capacity: 0,
            notes: "",
            region: "",
            rate: 0.0,
            contactEmail: "",
            limit: 0,
            patientRef: "",
            status: DenialSlotStatus.proposed
        )
    }
}
