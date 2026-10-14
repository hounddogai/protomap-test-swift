import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary rounding slot is in its life cycle.
    enum PrimaryRoundingSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary rounding slot. Its code is unique within a tenant.
    final class PrimaryRoundingSlot {
        var code: String
        var name: String
        var notes: String
        var pinned: Bool
        var retries: Int
        var rate: Double
        var weight: Double
        var active: Bool
        var windowDays: Int
        var specialty: String
        var status: PrimaryRoundingSlotStatus

        init(code: String, name: String, notes: String, pinned: Bool, retries: Int, rate: Double, weight: Double, active: Bool, windowDays: Int, specialty: String, status: PrimaryRoundingSlotStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.pinned = pinned
            self.retries = retries
            self.rate = rate
            self.weight = weight
            self.active = active
            self.windowDays = windowDays
            self.specialty = specialty
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

        func canMoveTo(_ next: PrimaryRoundingSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryRoundingSlotStatus.pending
            case .pending:
                return next == PrimaryRoundingSlotStatus.active || next == PrimaryRoundingSlotStatus.closed
            case .active:
                return next == PrimaryRoundingSlotStatus.suspended || next == PrimaryRoundingSlotStatus.closed
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

        func moveTo(_ next: PrimaryRoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return (weight * rate * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRoundingSlot {
            return PrimaryRoundingSlot(
                code: code,
                name: name,
                notes: notes,
                pinned: pinned,
                retries: retries,
                rate: rate,
                weight: weight,
                active: active,
                windowDays: windowDays,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary rounding slot in status draft.
    static func newPrimaryRoundingSlot(_ code: String, name: String) -> PrimaryRoundingSlot {
        return PrimaryRoundingSlot(
            code: code,
            name: name,
            notes: "",
            pinned: false,
            retries: 0,
            rate: 0.0,
            weight: 0.0,
            active: false,
            windowDays: 0,
            specialty: "",
            status: PrimaryRoundingSlotStatus.draft
        )
    }
}
