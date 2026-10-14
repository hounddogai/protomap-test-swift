import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy alert slot is in its life cycle.
    enum LegacyAlertSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy alert slot and its current status.
    final class LegacyAlertSlot {
        var code: String
        var label: String
        var channel: String
        var minimum: Double
        var discount: Double
        var ownerID: String
        var pinned: Bool
        var graceDays: Int
        var status: LegacyAlertSlotStatus

        init(code: String, label: String, channel: String, minimum: Double, discount: Double, ownerID: String, pinned: Bool, graceDays: Int, status: LegacyAlertSlotStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.minimum = minimum
            self.discount = discount
            self.ownerID = ownerID
            self.pinned = pinned
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LegacyAlertSlotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyAlertSlotStatus.active || next == LegacyAlertSlotStatus.closed
            case .active:
                return next == LegacyAlertSlotStatus.suspended || next == LegacyAlertSlotStatus.closed
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

        func moveTo(_ next: LegacyAlertSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy alert slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return ((minimum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAlertSlot {
            return LegacyAlertSlot(
                code: code,
                label: label,
                channel: channel,
                minimum: minimum,
                discount: discount,
                ownerID: ownerID,
                pinned: pinned,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy alert slot in status draft.
    static func newLegacyAlertSlot(_ code: String, label: String) -> LegacyAlertSlot {
        return LegacyAlertSlot(
            code: code,
            label: label,
            channel: "",
            minimum: 0.0,
            discount: 0.0,
            ownerID: "",
            pinned: false,
            graceDays: 0,
            status: LegacyAlertSlotStatus.draft
        )
    }
}
