import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped cleaning slot is in its life cycle.
    enum CappedCleaningSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped cleaning slot as the cleaning team keeps it.
    final class CappedCleaningSlot {
        var code: String
        var label: String
        var approved: Bool
        var diagnosisCode: String
        var createdAt: Int
        var weight: Double
        var contactEmail: String
        var status: CappedCleaningSlotStatus

        init(code: String, label: String, approved: Bool, diagnosisCode: String, createdAt: Int, weight: Double, contactEmail: String, status: CappedCleaningSlotStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.weight = weight
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: CappedCleaningSlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedCleaningSlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCleaningSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped cleaning slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> CappedCleaningSlot {
            return CappedCleaningSlot(
                code: code,
                label: label,
                approved: approved,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                weight: weight,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped cleaning slot in status proposed.
    static func newCappedCleaningSlot(_ code: String, label: String) -> CappedCleaningSlot {
        return CappedCleaningSlot(
            code: code,
            label: label,
            approved: false,
            diagnosisCode: "",
            createdAt: 0,
            weight: 0.0,
            contactEmail: "",
            status: CappedCleaningSlotStatus.proposed
        )
    }
}
