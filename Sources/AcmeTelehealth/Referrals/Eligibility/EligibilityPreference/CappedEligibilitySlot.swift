import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility slot is in its life cycle.
    enum CappedEligibilitySlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped eligibility slot, with what the planners need to act on it.
    final class CappedEligibilitySlot {
        var code: String
        var title: String
        var payer: String
        var ownerID: String
        var copay: Double
        var contactEmail: String
        var durationMinutes: Int
        var batchSize: Int
        var timezone: String
        var status: CappedEligibilitySlotStatus

        init(code: String, title: String, payer: String, ownerID: String, copay: Double, contactEmail: String, durationMinutes: Int, batchSize: Int, timezone: String, status: CappedEligibilitySlotStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.ownerID = ownerID
            self.copay = copay
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.timezone = timezone
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

        func canMoveTo(_ next: CappedEligibilitySlotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedEligibilitySlotStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedEligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((copay + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilitySlot {
            return CappedEligibilitySlot(
                code: code,
                title: title,
                payer: payer,
                ownerID: ownerID,
                copay: copay,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped eligibility slot in status planned.
    static func newCappedEligibilitySlot(_ code: String, title: String) -> CappedEligibilitySlot {
        return CappedEligibilitySlot(
            code: code,
            title: title,
            payer: "",
            ownerID: "",
            copay: 0.0,
            contactEmail: "",
            durationMinutes: 0,
            batchSize: 0,
            timezone: "",
            status: CappedEligibilitySlotStatus.planned
        )
    }
}
