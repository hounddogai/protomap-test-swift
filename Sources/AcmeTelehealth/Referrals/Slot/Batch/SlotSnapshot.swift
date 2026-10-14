import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot snapshot is in its life cycle.
    enum SlotSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A slot snapshot as the slot team keeps it.
    final class SlotSnapshot {
        var code: String
        var label: String
        var updatedAt: Int
        var currency: String
        var visitMinutes: Int
        var ward: String
        var specialty: String
        var graceDays: Int
        var status: SlotSnapshotStatus

        init(code: String, label: String, updatedAt: Int, currency: String, visitMinutes: Int, ward: String, specialty: String, graceDays: Int, status: SlotSnapshotStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.specialty = specialty
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

        func canMoveTo(_ next: SlotSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == SlotSnapshotStatus.pending || next == SlotSnapshotStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SlotSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return (Double(graceDays) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> SlotSnapshot {
            return SlotSnapshot(
                code: code,
                label: label,
                updatedAt: updatedAt,
                currency: currency,
                visitMinutes: visitMinutes,
                ward: ward,
                specialty: specialty,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a slot snapshot in status draft.
    static func newSlotSnapshot(_ code: String, label: String) -> SlotSnapshot {
        return SlotSnapshot(
            code: code,
            label: label,
            updatedAt: 0,
            currency: "",
            visitMinutes: 0,
            ward: "",
            specialty: "",
            graceDays: 0,
            status: SlotSnapshotStatus.draft
        )
    }
}
