import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending eligibility slot is in its life cycle.
    enum PendingEligibilitySlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending eligibility slot, with what the planners need to act on it.
    final class PendingEligibilitySlot {
        var code: String
        var title: String
        var procedureCode: String
        var label: String
        var minimum: Double
        var floorValue: Double
        var country: String
        var updatedAt: Int
        var status: PendingEligibilitySlotStatus

        init(code: String, title: String, procedureCode: String, label: String, minimum: Double, floorValue: Double, country: String, updatedAt: Int, status: PendingEligibilitySlotStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.label = label
            self.minimum = minimum
            self.floorValue = floorValue
            self.country = country
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PendingEligibilitySlotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingEligibilitySlotStatus.cancelled
            case .inProgress:
                return next == PendingEligibilitySlotStatus.completed || next == PendingEligibilitySlotStatus.cancelled
            case .completed:
                return next == PendingEligibilitySlotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingEligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((minimum + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingEligibilitySlot {
            return PendingEligibilitySlot(
                code: code,
                title: title,
                procedureCode: procedureCode,
                label: label,
                minimum: minimum,
                floorValue: floorValue,
                country: country,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending eligibility slot in status planned.
    static func newPendingEligibilitySlot(_ code: String, title: String) -> PendingEligibilitySlot {
        return PendingEligibilitySlot(
            code: code,
            title: title,
            procedureCode: "",
            label: "",
            minimum: 0.0,
            floorValue: 0.0,
            country: "",
            updatedAt: 0,
            status: PendingEligibilitySlotStatus.planned
        )
    }
}
