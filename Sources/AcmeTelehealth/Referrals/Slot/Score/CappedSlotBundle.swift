import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped slot bundle is in its life cycle.
    enum CappedSlotBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped slot bundle as the slot team keeps it.
    final class CappedSlotBundle {
        var code: String
        var name: String
        var allergy: String
        var active: Bool
        var threshold: Double
        var visible: Bool
        var currency: String
        var contactEmail: String
        var attempts: Int
        var notes: String
        var status: CappedSlotBundleStatus

        init(code: String, name: String, allergy: String, active: Bool, threshold: Double, visible: Bool, currency: String, contactEmail: String, attempts: Int, notes: String, status: CappedSlotBundleStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.active = active
            self.threshold = threshold
            self.visible = visible
            self.currency = currency
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.notes = notes
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

        func canMoveTo(_ next: CappedSlotBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CappedSlotBundleStatus.active || next == CappedSlotBundleStatus.suspended
            case .active:
                return next == CappedSlotBundleStatus.suspended
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

        func moveTo(_ next: CappedSlotBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped slot bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return (threshold * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> CappedSlotBundle {
            return CappedSlotBundle(
                code: code,
                name: name,
                allergy: allergy,
                active: active,
                threshold: threshold,
                visible: visible,
                currency: currency,
                contactEmail: contactEmail,
                attempts: attempts,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped slot bundle in status draft.
    static func newCappedSlotBundle(_ code: String, name: String) -> CappedSlotBundle {
        return CappedSlotBundle(
            code: code,
            name: name,
            allergy: "",
            active: false,
            threshold: 0.0,
            visible: false,
            currency: "",
            contactEmail: "",
            attempts: 0,
            notes: "",
            status: CappedSlotBundleStatus.draft
        )
    }
}
