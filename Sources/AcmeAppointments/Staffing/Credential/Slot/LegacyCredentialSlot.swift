import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy credential slot is in its life cycle.
    enum LegacyCredentialSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a legacy credential slot and its current status.
    final class LegacyCredentialSlot {
        var code: String
        var label: String
        var dosageMg: Double
        var weight: Double
        var reviewer: String
        var graceDays: Int
        var status: LegacyCredentialSlotStatus

        init(code: String, label: String, dosageMg: Double, weight: Double, reviewer: String, graceDays: Int, status: LegacyCredentialSlotStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.weight = weight
            self.reviewer = reviewer
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LegacyCredentialSlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyCredentialSlotStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyCredentialSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCredentialSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy credential slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy credential slot") \(code)"
        }

        func effectiveTotal() -> Double {
            return (dosageMg * weight * 100).rounded() / 100
        }

        func copyValue() -> LegacyCredentialSlot {
            return LegacyCredentialSlot(
                code: code,
                label: label,
                dosageMg: dosageMg,
                weight: weight,
                reviewer: reviewer,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy credential slot in status requested.
    static func newLegacyCredentialSlot(_ code: String, label: String) -> LegacyCredentialSlot {
        return LegacyCredentialSlot(
            code: code,
            label: label,
            dosageMg: 0.0,
            weight: 0.0,
            reviewer: "",
            graceDays: 0,
            status: LegacyCredentialSlotStatus.requested
        )
    }
}
