import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan item is in its life cycle.
    enum DischargePlanItemStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a discharge plan item and its current status.
    final class DischargePlanItem {
        var code: String
        var label: String
        var ward: String
        var notes: String
        var externalRef: String
        var startsAt: Int
        var attempts: Int
        var contactEmail: String
        var priority: Int
        var status: DischargePlanItemStatus

        init(code: String, label: String, ward: String, notes: String, externalRef: String, startsAt: Int, attempts: Int, contactEmail: String, priority: Int, status: DischargePlanItemStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.notes = notes
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.attempts = attempts
            self.contactEmail = contactEmail
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanItemStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DischargePlanItemStatus.draining
            case .ready:
                return next == DischargePlanItemStatus.draining || next == DischargePlanItemStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DischargePlanItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(priority) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanItem {
            return DischargePlanItem(
                code: code,
                label: label,
                ward: ward,
                notes: notes,
                externalRef: externalRef,
                startsAt: startsAt,
                attempts: attempts,
                contactEmail: contactEmail,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a discharge plan item in status idle.
    static func newDischargePlanItem(_ code: String, label: String) -> DischargePlanItem {
        return DischargePlanItem(
            code: code,
            label: label,
            ward: "",
            notes: "",
            externalRef: "",
            startsAt: 0,
            attempts: 0,
            contactEmail: "",
            priority: 0,
            status: DischargePlanItemStatus.idle
        )
    }
}
